package mobile;

import haxe.Json;
import haxe.io.Path;
import flixel.util.FlxSave;
import openfl.utils.Assets;
import sys.FileSystem;

using StringTools;

enum ButtonModes
{
	ACTION;
	DPAD;
	HITBOX;
}

class MobileConfig {
	public static var actionModes:Map<String, MobileButtonsData> = new Map();
	public static var dpadModes:Map<String, MobileButtonsData> = new Map();
	public static var hitboxModes:Map<String, CustomHitboxData> = new Map();
	public static var mobileFolderPath:String = 'mobile/';

	public static var save:FlxSave;
	public static function init(saveName:String, savePath:String, mobilePath:String = 'mobile/', folders:Array<Array<Dynamic>>)
	{
		save = new FlxSave();
		save.bind(saveName, savePath);
		if (mobilePath != null || mobilePath != '') mobileFolderPath = (mobilePath.endsWith('/') ? mobilePath : mobilePath + '/');

		for (folder in folders) {
			switch (folder[1]) {
				case ACTION:
					setDefaultMap('assets/' + mobileFolderPath + folder[0], actionModes, ACTION);
					#if MOD_SUPPORT
					final moddyFolder:String = ModsFolder.getCurrentModAssetPath('mobile/MobilePad');
					if (ModsFolder.assetPathExists(moddyFolder))
					{
						setModMap('$moddyFolder/ActionModes', actionModes, ACTION);
					}
					#end
				case DPAD:
					setDefaultMap('assets/' + mobileFolderPath + folder[0], dpadModes, DPAD);
					#if MOD_SUPPORT
					final moddyFolder:String = ModsFolder.getCurrentModAssetPath('mobile/MobilePad');
					if (ModsFolder.assetPathExists(moddyFolder))
					{
						setModMap('$moddyFolder/DPadModes', dpadModes, DPAD);
					}
					#end
				case HITBOX:
					setDefaultMap('assets/' + mobileFolderPath + folder[0], hitboxModes, HITBOX);
					#if MOD_SUPPORT
					final moddyFolder:String = ModsFolder.getCurrentModAssetPath('mobile/Hitbox');
					if (ModsFolder.assetPathExists(moddyFolder))
					{
						setModMap('$moddyFolder/HitboxModes', hitboxModes, HITBOX);
					}
					#end
			}
		}
	}

	private static function setDefaultMap(folder:String, map:Dynamic, mode:ButtonModes)
	{
		for (file in readDirectory(folder))
		{
			if (Path.extension(file) == 'json')
			{
				file = Path.join([folder, Path.withoutDirectory(file)]);
				var str = Assets.getText(file);
				if (mode == HITBOX) {
					var json:CustomHitboxData = cast Json.parse(str);
					var mapKey:String = Path.withoutDirectory(Path.withoutExtension(file));
					map.set(mapKey, json);
				}
				else if (mode == ACTION || mode == DPAD) {
					var json:MobileButtonsData = cast Json.parse(str);
					var mapKey:String = Path.withoutDirectory(Path.withoutExtension(file));
					map.set(mapKey, json);
				}
			}
		}
	}

	private static function readDirectory(path:String):Array<String>
	{
		var filteredList:Array<String> = Assets.list().filter(f -> f.startsWith(path));
		var results:Array<String> = [];
		for (i in filteredList.copy())
		{
			var slashsCount:Int = path.split('/').length;
			if (path.endsWith('/'))
				slashsCount -= 1;

			if (i.split('/').length - 1 != slashsCount)
			{
				filteredList.remove(i);
			}
		}
		for (item in filteredList)
		{
			@:privateAccess
			for (library in lime.utils.Assets.libraries.keys())
			{
				var libPath:String = '$library:$item';
				if (library != 'default' && Assets.exists(libPath) && !results.contains(libPath))
					results.push(libPath);
				else if (Assets.exists(item) && !results.contains(item))
					results.push(item);
			}
		}
		return results.map(f -> f.substr(f.lastIndexOf("/") + 1));
	}

	#if MOD_SUPPORT
	private static function setModMap(folder:String, map:Dynamic, mode:ButtonModes)
	{
		if (folder == null || folder == "")
			return;

		if (FileSystem.exists(folder) && FileSystem.isDirectory(folder)) {
			for (file in FileSystem.readDirectory(folder))
			{
				if (Path.extension(file) == 'json')
				{
					file = Path.join([folder, Path.withoutDirectory(file)]);
					var str = File.getContent(file);
					if (mode == HITBOX) {
						var json:CustomHitboxData = cast Json.parse(str);
						var mapKey:String = Path.withoutDirectory(Path.withoutExtension(file));
						map.set(mapKey, json);
					}
					else if (mode == ACTION || mode == DPAD) {
						var json:MobileButtonsData = cast Json.parse(str);
						var mapKey:String = Path.withoutDirectory(Path.withoutExtension(file));
						map.set(mapKey, json);
					}
				}
			}
			return;
		}

		var prefix = folder.endsWith("/") ? folder : folder + "/";
		var prefixLower = prefix.toLowerCase();
		for (asset in Assets.list()) {
			var cleanAsset = asset;
			var separator = cleanAsset.indexOf(":");
			if (separator != -1)
				cleanAsset = cleanAsset.substr(separator + 1);

			if (!cleanAsset.toLowerCase().startsWith(prefixLower))
				continue;

			var fileName = cleanAsset.substr(prefix.length);
			if (fileName.indexOf("/") != -1 || Path.extension(fileName) != "json")
				continue;

			var str = Assets.getText(asset);
			if (mode == HITBOX) {
				var json:CustomHitboxData = cast Json.parse(str);
				var mapKey:String = Path.withoutDirectory(Path.withoutExtension(fileName));
				map.set(mapKey, json);
			}
			else if (mode == ACTION || mode == DPAD) {
				var json:MobileButtonsData = cast Json.parse(str);
				var mapKey:String = Path.withoutDirectory(Path.withoutExtension(fileName));
				map.set(mapKey, json);
			}
		}
	}
	#end
}

typedef MobileButtonsData =
{
	buttons:Array<ButtonsData>
}

typedef CustomHitboxData =
{
	hints:Array<HitboxData>, //support library's jsons
	none:Array<HitboxData>,
	single:Array<HitboxData>,
	double:Array<HitboxData>,
	triple:Array<HitboxData>,
	quad:Array<HitboxData>
}

typedef HitboxData =
{
	button:String, // what Hitbox Button should be used, must be a valid Hitbox Button var from Hitbox as a string.
	buttonIDs:Array<String>, // what Hitbox Button Iad should be used, If you're using a the library for PsychEngine 0.7 Versions, This is useful.
	buttonUniqueID:Dynamic, // the button's special ID for button
	//if custom ones isn't setted these will be used
	x:Dynamic, // the button's X position on screen.
	y:Dynamic, // the button's Y position on screen.
	width:Dynamic, // the button's Width on screen.
	height:Dynamic, // the button's Height on screen.
	position:Array<Float>,
	scale:Array<Int>,
	color:String, // the button color, default color is white.
	returnKey:String, // the button return, default return is nothing (please don't add custom return if you don't need).
	extraKeyMode:Null<Int>,
	//Top
	topPosition:Array<Float>,
	topScale:Array<Int>,
	topColor:String,
	topReturnKey:String,
	topExtraKeyMode:Null<Int>,
}


typedef ButtonsData =
{
	button:String, // the button's name for checking pressed directly.
	buttonIDs:Array<String>, // what MobileButton Button IDs should be used.
	buttonUniqueID:Dynamic, // the button's special ID for button
	graphic:String, // the graphic of the button, usually can be located in the MobilePad xml.
	position:Array<Null<Float>>, // the button's X/Y position on screen.
	color:String, // the button color, default color is white.
	scale:Null<Float>, //the button scale, default scale is 1.
	returnKey:String // the button return, default return is nothing but If you're game using a lua scripting this will be useful.
}
