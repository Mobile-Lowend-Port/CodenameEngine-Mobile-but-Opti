package funkin.backend.assets;

import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.backend.system.Main;
import funkin.backend.system.MainState;
import haxe.io.Path;
import lime.text.Font;
import openfl.text.Font as OpenFLFont;
import openfl.utils.AssetLibrary;
import openfl.utils.AssetManifest;
import openfl.utils.Assets;

using StringTools;
#if MOD_SUPPORT
import sys.FileSystem;
import sys.io.File;
#end


class ModsFolder {
	private static final EMBEDDED_MOD_FOLDERS:Array<String> = ["assets/mods", "mods"];

	/**
	 * INTERNAL - Only use when editing source mods!!
	 */
	@:dox(hide) public static var onModSwitch:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

	/**
	 * Current mod folder. Will affect `Paths`.
	 */
	public static var currentModFolder:String = null;
	/**
	 * Path to the `mods` folder.
	 */
	public static var modsPath:String = #if mobile MobileUtil.getModsDirectory() #else Sys.getCwd() + "mods/" #end;
	/**
	 * Path to the `addons` folder.
	 */
	public static var addonsPath:String = #if mobile MobileUtil.getAddonsDirectory() #else Sys.getCwd() + "addons/" #end;

	public static var extraModsPaths:Array<String> = [];
	public static var extraAddonsPaths:Array<String> = [];

	/**
	 * If accessing a file as assets/data/global/LIB_mymod.hx should redirect to mymod:assets/data/global.hx
	 */
	public static var useLibFile:Bool = true;

	/**
	 * Whenever its the first time mods has been reloaded.
	 */
	private static var __firstTime:Bool = true;

	public static inline function isDefaultMod(mod:String):Bool {
		return mod == null || mod == "" || mod == "default";
	}

	public static function isEmbeddedMod(mod:String):Bool
		return getFilesystemModRoot(mod) == null && getEmbeddedModAssetRoot(mod) != null;

	private static function cleanAssetPath(path:String):String {
		var cleanPath = path;
		var separator = cleanPath.indexOf(":");
		if (separator != -1)
			cleanPath = cleanPath.substr(separator + 1);
		return cleanPath;
	}

	private static function normalizePath(path:String):String {
		path = StringTools.replace(path, "\\", "/");
		while (path.endsWith("/"))
			path = path.substr(0, path.length - 1);
		return path;
	}

	private static function normalizeDirectory(path:String):String {
		path = StringTools.replace(path, "\\", "/");
		if (!path.endsWith("/"))
			path += "/";
		return path;
	}

	private static function trimRelativePath(path:String):String {
		path = StringTools.replace(path, "\\", "/");
		while (path.startsWith("/"))
			path = path.substr(1);
		return path;
	}

	static function filesystemExists(path:String):Bool {
		#if MOD_SUPPORT
		return try FileSystem.exists(path) catch (e:Dynamic) false;
		#else
		return false;
		#end
	}

	static function filesystemIsDirectory(path:String):Bool {
		#if MOD_SUPPORT
		return try FileSystem.exists(path) && FileSystem.isDirectory(path) catch (e:Dynamic) false;
		#else
		return false;
		#end
	}

	static function filesystemReadDirectory(path:String):Array<String> {
		#if MOD_SUPPORT
		return try FileSystem.readDirectory(path) catch (e:Dynamic) null;
		#else
		return null;
		#end
	}

	public static function getEmbeddedModAssetRoot(mod:String):String {
		if (isDefaultMod(mod))
			return null;

		var modLower = mod.toLowerCase();

		for (asset in Assets.list()) {
			var cleanPath = cleanAssetPath(asset);
			var cleanLower = cleanPath.toLowerCase();

			for (root in EMBEDDED_MOD_FOLDERS) {
				var rootPrefixLower = (root + "/").toLowerCase();
				if (!cleanLower.startsWith(rootPrefixLower))
					continue;

				var relative = cleanPath.substr(root.length + 1);
				var slashIndex = relative.indexOf("/");
				if (slashIndex <= 0)
					continue;

				var embeddedModName = relative.substr(0, slashIndex);
				if (embeddedModName.toLowerCase() == modLower)
					return '$root/$embeddedModName';
			}
		}

		return null;
	}

	public static function getCurrentModRoot():String {
		if (isDefaultMod(currentModFolder))
			return #if (sys && !mobile && TEST_BUILD) '${Main.pathBack}assets/' #else 'assets' #end;

		var filesystemRoot = getFilesystemModRoot(currentModFolder);
		if (filesystemRoot != null)
			return filesystemRoot;

		var embeddedRoot = getEmbeddedModAssetRoot(currentModFolder);
		if (embeddedRoot != null)
			return embeddedRoot;

		return '${modsPath}${currentModFolder}';
	}

	public static function getModAssetPath(mod:String, ?relativePath:String):String {
		if (isDefaultMod(mod))
			return null;

		var root = getFilesystemModRoot(mod);
		if (root == null) {
			root = getEmbeddedModAssetRoot(mod);
			if (root == null)
				root = normalizePath('${modsPath}${mod}');
		}

		if (relativePath == null || relativePath == "")
			return root;

		return root + "/" + trimRelativePath(relativePath);
	}

	public static inline function getCurrentModAssetPath(?relativePath:String):String
		return getModAssetPath(currentModFolder, relativePath);

	public static function assetPathExists(path:String):Bool {
		if (path == null || path == "")
			return false;

		path = normalizePath(path);

		#if MOD_SUPPORT
		if (filesystemExists(path))
			return true;
		#end

		if (Assets.exists(path))
			return true;

		var prefix = path + "/";
		var prefixLower = prefix.toLowerCase();
		for (asset in Assets.list()) {
			if (cleanAssetPath(asset).toLowerCase().startsWith(prefixLower))
				return true;
		}

		return false;
	}

	public static function getModSearchPaths():Array<String> {
		refreshExtraSearchPaths();

		var paths:Array<String> = [];
		function addPath(path:String):Void {
			path = normalizeDirectory(path);
			if (!paths.contains(path))
				paths.push(path);
		}

		addPath(modsPath);
		for (path in extraModsPaths)
			addPath(path);
		return paths;
	}

	public static function getAddonSearchPaths():Array<String> {
		refreshExtraSearchPaths();

		var paths:Array<String> = [];
		function addPath(path:String):Void {
			path = normalizeDirectory(path);
			if (!paths.contains(path))
				paths.push(path);
		}

		addPath(addonsPath);
		for (path in extraAddonsPaths)
			addPath(path);
		return paths;
	}

	public static function getFilesystemModRoot(mod:String):String {
		if (isDefaultMod(mod))
			return null;

		#if MOD_SUPPORT
		for (root in getModSearchPaths()) {
			var modRoot = normalizePath(root + mod);
			if (filesystemExists(modRoot))
				return modRoot;

			for (ext in Flags.ALLOWED_ZIP_EXTENSIONS) {
				if (filesystemExists('$modRoot.$ext'))
					return modRoot;
			}
		}
		#end

		return null;
	}

	public static function getAutoloadMod():String {
		#if MOD_SUPPORT
		for (root in getModSearchPaths()) {
			var autoloadPath = normalizePath(root + "autoload.txt");
			if (filesystemExists(autoloadPath)) {
				try return File.getContent(autoloadPath).trim()
				catch (e:Dynamic) Logs.warn('Could not read autoload file "$autoloadPath": ${Std.string(e)}');
			}
		}
		#end

		if (Assets.exists("assets/mods/autoload.txt"))
			return Assets.getText("assets/mods/autoload.txt").trim();
		if (Assets.exists("mods/autoload.txt"))
			return Assets.getText("mods/autoload.txt").trim();

		return null;
	}

	static function refreshExtraSearchPaths():Void {
		#if mobile
		extraModsPaths = [];
		extraAddonsPaths = [];

		for (root in MobileUtil.getModSearchDirectories()) {
			var mods = normalizeDirectory(root + "mods/");
			var addons = normalizeDirectory(root + "addons/");

			if (mods != normalizeDirectory(modsPath) && !extraModsPaths.contains(mods))
				extraModsPaths.push(mods);
			if (addons != normalizeDirectory(addonsPath) && !extraAddonsPaths.contains(addons))
				extraAddonsPaths.push(addons);
		}
		#end
	}

	/**
	 * Initializes `mods` folder.
	 */
	public static function init() {
		refreshExtraSearchPaths();
		try {
			if (!filesystemExists(modsPath)) FileSystem.createDirectory(modsPath);
		} catch (e:Dynamic) {
			Logs.warn('Could not create mods folder "$modsPath": ${Std.string(e)}');
		}

		try {
			if (!filesystemExists(addonsPath)) FileSystem.createDirectory(addonsPath);
		} catch (e:Dynamic) {
			Logs.warn('Could not create addons folder "$addonsPath": ${Std.string(e)}');
		}

		if(!getModsList().contains(Options.lastLoadedMod)) {
			if(Options.lastLoadedMod != null)
				Logs.warn("Mod \"" + Options.lastLoadedMod + "\" not found in mods list, switching to base game!");
			Options.lastLoadedMod = null;
		}
	}

	/**
	 * Switches mod - unloads all the other mods, then load this one.
	 * @param libName
	 */
	public static function switchMod(mod:String) {
		Options.lastLoadedMod = currentModFolder = mod;
		reloadMods();
		if(mod == null) {
			mod = "(default)";
		}
		Logs.traceColored([
			Logs.logText('Switched to mod: '),
			Logs.logText(mod, GREEN)
		], VERBOSE);
	}

	public static function reloadMods() {
		if (!__firstTime)
			FlxG.switchState(new MainState());
		__firstTime = false;
	}

	/**
	 * Loads a mod library from the specified path. Supports folders and zips.
	 * @param modName Name of the mod
	 * @param force Whenever the mod should be reloaded if it has already been loaded
	 */
	public static function loadModLib(path:String, force:Bool = false, ?modName:String) {
		#if MOD_SUPPORT
		path = normalizePath(path);

		if (modName == null || modName == "") {
			var trimmedPath = path;
			while (trimmedPath.endsWith("/"))
				trimmedPath = trimmedPath.substr(0, trimmedPath.length - 1);
			modName = Path.withoutDirectory(trimmedPath);
		}

		for (ext in Flags.ALLOWED_ZIP_EXTENSIONS) {
			if (!filesystemExists('$path.$ext')) continue;
			return loadLibraryFromZip('$path'.toLowerCase(), '$path.$ext', force, modName);
		}

		if (filesystemExists(path))
			return loadLibraryFromFolder('$path'.toLowerCase(), '$path', force, modName);

		var embeddedRoot = getEmbeddedModAssetRoot(modName);
		if (embeddedRoot != null)
			return loadLibraryFromAssets(embeddedRoot.toLowerCase(), embeddedRoot, force, modName);

		return loadLibraryFromFolder('$path'.toLowerCase(), '$path', force, modName);

		#else
		return null;
		#end
	}

	public static function getModsList():Array<String> {
		var mods:Array<String> = [];
		#if MOD_SUPPORT
		for (modsPath in getModSearchPaths()) {
			if (!filesystemExists(modsPath))
				continue;

			final modsList:Array<String> = filesystemReadDirectory(modsPath);

			if (modsList != null) {
				for (modFolder in modsList) {
					var modName = modFolder;

					if (!filesystemIsDirectory(modsPath + modFolder)) {
						if (!Flags.ALLOWED_ZIP_EXTENSIONS.contains(Path.extension(modFolder)))
							continue;
						modName = Path.withoutExtension(modFolder);
					}

					if (!mods.contains(modName))
						mods.push(modName);
				}
			}
		}

		for (asset in Assets.list()) {
			var cleanPath = cleanAssetPath(asset);
			var cleanLower = cleanPath.toLowerCase();

			for (root in EMBEDDED_MOD_FOLDERS) {
				var rootPrefix = (root + "/").toLowerCase();
				if (!cleanLower.startsWith(rootPrefix))
					continue;

				var relative = cleanPath.substr(rootPrefix.length);
				var slashIndex = relative.indexOf("/");
				if (slashIndex <= 0)
					continue;

				var modName = relative.substr(0, slashIndex);
				if (!mods.contains(modName))
					mods.push(modName);
			}
		}
		#end
		return mods;
	}
	public static function getLoadedModsLibs(skipTranslated:Bool = false):Array<IModsAssetLibrary> {
		var libs = [];
		for (i in Paths.assetsTree.libraries) {
			var l = AssetsLibraryList.getCleanLibrary(i);
			#if TRANSLATIONS_SUPPORT
			if(skipTranslated && (l is TranslatedAssetLibrary)) continue;
			#end
			// No need to check for it being a `ScriptedAssetLibrary`, if `ScriptedAssetLibrary` extends ModsFolderLibrary, which implements `IModsAssetLibrary`
			// If you have to revert this change then uhhhhh wasn't me, trust 🙏
			if (/*l is ScriptedAssetLibrary ||*/ l is IModsAssetLibrary) libs.push(cast(l, IModsAssetLibrary));
		}
		return libs;
	}
	public static function getLoadedMods(skipTranslated:Bool = false):Array<String>
		return [for (modLib in getLoadedModsLibs(skipTranslated)) modLib.modName];

	public static function prepareLibrary(libName:String, force:Bool = false) {
		var assets:AssetManifest = new AssetManifest();
		assets.name = libName;
		assets.version = 2;
		assets.libraryArgs = [];
		assets.assets = [];

		return AssetLibrary.fromManifest(assets);
	}

	public static function registerFont(font:Font) {
		var openflFont = new OpenFLFont();
		@:privateAccess
		openflFont.__fromLimeFont(font);
		OpenFLFont.registerFont(openflFont);
		return font;
	}

	public static function prepareModLibrary(libName:String, lib:IModsAssetLibrary, force:Bool = false, ?tag:AssetSource) {
		var openLib = prepareLibrary(libName, force);
		lib.prefix = 'assets/';
		@:privateAccess
		openLib.__proxy = cast(lib, lime.utils.AssetLibrary);
		if (tag != null) {
			openLib.tag = tag;
			cast(lib, lime.utils.AssetLibrary).tag = tag;
		}
		return openLib;
	}

	#if MOD_SUPPORT
	public static function loadLibraryFromFolder(libName:String, folder:String, force:Bool = false, ?modName:String, ?tag:AssetSource = MODS) {
		return prepareModLibrary(libName, new ModsFolderLibrary(folder, libName, modName), force, tag);
	}

	public static function loadLibraryFromAssets(libName:String, assetRoot:String, force:Bool = false, ?modName:String, ?tag:AssetSource = MODS) {
		return prepareModLibrary(libName, new EmbeddedModsFolderLibrary(assetRoot, libName, modName), force, tag);
	}

	public static function loadLibraryFromZip(libName:String, zipPath:String, force:Bool = false, ?modName:String, ?tag:AssetSource = MODS) {
		return prepareModLibrary(libName, new ZipFolderLibrary(zipPath, libName, modName), force, tag);
	}
	#end
}
