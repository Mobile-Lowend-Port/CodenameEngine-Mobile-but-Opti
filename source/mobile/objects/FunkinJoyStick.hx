package mobile.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.backend.assets.ModsFolder;
import openfl.utils.Assets;
import openfl.display.BitmapData;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

import mobile.JoyStick;

using StringTools;

class FunkinJoyStick extends JoyStick {
	//FNF Asset Stuff
	override private function loadObjectGraphic(object:FlxSprite, graphic:String, img:String) {
		var fixedModPath:String = graphic;
		if (!graphic.startsWith(MobileConfig.mobileFolderPath))
			graphic = MobileConfig.mobileFolderPath + graphic;

		#if MOD_SUPPORT
		final moddyFolder:String = ModsFolder.getCurrentModAssetPath('mobile');
		#end

		#if MOD_SUPPORT
		var xmlGraphicExists:Bool = (FileSystem.exists('$graphic.xml') && FileSystem.exists('$graphic.png'));
		var modGraphicXml:String = moddyFolder != null ? '$moddyFolder/$fixedModPath.xml' : null;
		var modGraphicPng:String = moddyFolder != null ? '$moddyFolder/$fixedModPath.png' : null;
		if (modGraphicXml != null && modGraphicPng != null && ModsFolder.assetPathExists(modGraphicXml) && ModsFolder.assetPathExists(modGraphicPng)) {
			if (FileSystem.exists(modGraphicXml) && FileSystem.exists(modGraphicPng))
				object.loadGraphic(FlxGraphic.fromFrame(FlxAtlasFrames.fromSparrow(BitmapData.fromBytes(File.getBytes(modGraphicPng)), File.getContent(modGraphicXml)).getByName(img)));
			else
				object.loadGraphic(FlxGraphic.fromFrame(FlxAtlasFrames.fromSparrow(Assets.getBitmapData(modGraphicPng), Assets.getText(modGraphicXml)).getByName(img)));
		}
		else if (xmlGraphicExists)
			object.loadGraphic(FlxGraphic.fromFrame(FlxAtlasFrames.fromSparrow(BitmapData.fromBytes(File.getBytes('$graphic.png')), File.getContent('$graphic.xml')).getByName(img)));
		else #end {
			var assetGraphic:String = '$graphic.png';
			var assetXml:String = '$graphic.xml';
			var embeddedGraphic:String = 'assets/$assetGraphic';
			var embeddedXml:String = 'assets/$assetXml';
			if (!Assets.exists(assetGraphic) && Assets.exists(embeddedGraphic)) {
				assetGraphic = embeddedGraphic;
				assetXml = embeddedXml;
			}
			object.loadGraphic(FlxGraphic.fromFrame(FlxAtlasFrames.fromSparrow(Assets.getBitmapData(assetGraphic), Assets.getText(assetXml)).getByName(img)));
		}
	}

	public function new(x:Float = 0, y:Float = 0, ?graphic:String, ?onMove:Float->Float->Float->String->Void)
	{
		super(x, y, graphic, onMove);
	}
}
