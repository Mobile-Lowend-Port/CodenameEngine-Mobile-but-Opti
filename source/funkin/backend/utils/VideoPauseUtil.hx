package funkin.backend.utils;

#if VIDEO_CUTSCENES
import flixel.FlxG;
import hxvlc.flixel.FlxVideoSprite;
#end

class VideoPauseUtil {
	#if VIDEO_CUTSCENES
	static var videos:Array<FlxVideoSprite> = [];
	static var focusPaused:Array<FlxVideoSprite> = [];

	public static function register(video:FlxVideoSprite):Void {
		if (video != null && videos.indexOf(video) < 0)
			videos.push(video);
	}

	public static function unregister(video:FlxVideoSprite):Void {
		if (video == null) return;
		while (videos.remove(video)) {}
		while (focusPaused.remove(video)) {}
	}

	public static function pauseAllForFocusLost():Void {
		for (video in videos.copy())
			pauseForFocusLost(video);
	}

	public static function pauseAllIfGamePaused():Void {
		if (!isGamePausedForVideo())
			return;

		pauseAllForGamePause();
	}

	public static function pauseAllForGamePause():Void {
		focusPaused = [];
		for (video in videos.copy()) {
			if (video == null || video.bitmap == null)
				continue;
			try {
				video.pause();
			} catch(e:Dynamic) {}
		}
	}

	public static function pauseForFocusLost(video:FlxVideoSprite):Void {
		if (video == null || video.bitmap == null) return;

		try {
			if (video.bitmap.isPlaying && focusPaused.indexOf(video) < 0)
				focusPaused.push(video);
			video.pause();
		} catch(e:Dynamic) {}
	}

	public static function resumeForFocusGained(video:FlxVideoSprite):Void {
		if (video == null || video.bitmap == null) return;

		if (focusPaused.remove(video)) {
			if (isGamePausedForVideo()) {
				try {
					video.pause();
				} catch(e:Dynamic) {}
				return;
			}

			try {
				video.resume();
			} catch(e:Dynamic) {}
		}
	}

	public static function canAutoResume():Bool {
		return !isGamePausedForVideo();
	}

	static function isGamePausedForVideo():Bool {
		var playState = funkin.game.PlayState.instance;
		if (playState != null && playState.paused)
			return true;

		if (FlxG.state != null && FlxG.state.subState != null && Std.isOfType(FlxG.state.subState, funkin.menus.PauseSubState))
			return true;

		return false;
	}
	#else
	public static inline function register(video:Dynamic):Void {}
	public static inline function unregister(video:Dynamic):Void {}
	public static inline function pauseAllForFocusLost():Void {}
	public static inline function pauseAllIfGamePaused():Void {}
	public static inline function pauseAllForGamePause():Void {}
	public static inline function pauseForFocusLost(video:Dynamic):Void {}
	public static inline function resumeForFocusGained(video:Dynamic):Void {}
	public static inline function canAutoResume():Bool return true;
	#end
}
