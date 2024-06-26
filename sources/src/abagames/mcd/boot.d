/*
 * $Id: boot.d,v 1.3 2006/03/18 03:36:00 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.mcd.boot;

private import std.string;
private import std.conv;
private import std.math;
private import core.stdc.stdlib;
private import abagames.util.logger;
private import abagames.util.tokenizer;
private import abagames.util.sdl.mainloop;
private import abagames.util.sdl.input;
private import abagames.util.sdl.twinstickpad;
private import abagames.util.sdl.recordableinput;
private import abagames.util.sdl.sound;
private import abagames.mcd.screen;
private import abagames.mcd.gamemanager;
private import abagames.mcd.prefmanager;

/**
 * Boot the game.
 */
private:
Screen screen;
RecordableTwinStickPad input;
GameManager gameManager;
PrefManager prefManager;
MainLoop mainLoop;

version (Win32_release) {
  // Boot as the Windows executable.
  private import core.runtime;
  private import core.sys.windows.windows;

  extern (Windows)
  public int WinMain(HINSTANCE hInstance,
		     HINSTANCE hPrevInstance,
		     LPSTR lpCmdLine,
		     int nCmdShow) {
    int result;
    try {
      Runtime.initialize();
      char[4096] exe;
      GetModuleFileNameA(null, exe.ptr, 4096);
      string[1] prog;
      prog[0] = to!string(exe);
      result = boot(prog ~ std.string.split(to!string(lpCmdLine)));
      Runtime.terminate();
    } catch (Throwable o) {
      Logger.error("Exception: " ~ o.toString());
      result = EXIT_FAILURE;
    }
    return result;
  }
} else {
  // Boot as the general executable.
  public int main(string[] args) {
    return boot(args);
  }
}

public int boot(string[] args) {
  screen = new Screen;
  input = new RecordableTwinStickPad;
  gameManager = new GameManager;
  prefManager = new PrefManager;
  mainLoop = new MainLoop(screen, input, gameManager, prefManager);
  try {
    parseArgs(args, screen);
  } catch (Exception e) {
    return EXIT_FAILURE;
  }
  mainLoop.loop();
  return EXIT_SUCCESS;
}

private void parseArgs(string[] commandArgs, Screen screen) {
  string[] args = readOptionsIniFile();
  for (int i = 1; i < commandArgs.length; i++)
    args ~= commandArgs[i];
  string progName = commandArgs[0];
  for (int i = 0; i < args.length; i++) {
    switch (args[i]) {
    case "-brightness":
      if (i >= args.length - 1) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      float b = cast(float) to!int(args[i]) / 100;
      if (b < 0 || b > 1) {
        usage(args[0]);
        throw new Exception("Invalid options");
      }
      Screen.brightness = b;
      break;
    case "-window":
      screen.windowMode = true;
      break;
    case "-res":
      if (i >= args.length - 2) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      int w = to!int(args[i]);
      i++;
      int h = to!int(args[i]);
      screen.screenWidth = w;
      screen.screenHeight = h;
      break;
    case "-nosound":
      SoundManager.noSound = true;
      break;
    case "-exchange":
      TwinStickPad.buttonReversed = true;
      break;
    case "-rotatestick2":
    case "-rotaterightstick":
      if (i >= args.length - 1) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      TwinStickPad.rotate = cast(float) to!int(args[i]) * PI / 180.0f;
      break;
    case "-reversestick2":
    case "-reverserightstick":
      TwinStickPad.reverse = -1;
      break;
    case "-disablestick2":
      TwinStickPad.disableStick2 = true;
      break;
    case "-enableaxis5":
      TwinStickPad.enableAxis5 = true;
      break;
    case "-accframe":
      mainLoop.accframe = 1;
      break;
    default:
      usage(progName);
      throw new Exception("Invalid options");
    }
  }
}

private string OPTIONS_INI_FILE = "options.ini";

private string[] readOptionsIniFile() {
  try {
    return Tokenizer.readFile(OPTIONS_INI_FILE, " ");
  } catch (Exception e) {
    return null;
  }
}

private void usage(string progName) {
  Logger.error
    ("Usage: " ~ progName ~ " [-window] [-res x y] [-brightness [0-100]] [-nosound] [-exchange] [-rotatestick2 deg] [-reversestick2] [-disablestick2] [-enableaxis5]");
}
