/*
 * $Id: barrage.d,v 1.3 2006/03/18 02:42:50 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.mcd.barrage;

private import std.math;
private import std.string;
private import std.path;
private import std.file;
private import bulletml;
private import abagames.util.logger;
private import abagames.mcd.bullet;
private import abagames.mcd.bulletpool;
private import abagames.mcd.bulletimpl;
private import abagames.mcd.bullettarget;

/**
 * Barrage pattern.
 */
public class Barrage {
 private:
  ParserParam[] parserParam;
  int prevWait, postWait;

  public void setWait(int prevWait, int postWait) {
    this.prevWait = prevWait;
    this.postWait = postWait;
  }

  public void addBml(BulletMLParser *p, float rank, float speed) {
    parserParam ~= new ParserParam(p, rank, speed);
  }

  public void addBml(string bmlDirName, string bmlFileName, float rank, float speed) {
    BulletMLParser *p = BarrageManager.getInstance(bmlDirName, bmlFileName);
    if (!p)
      throw new Error("File not found: " ~ bmlDirName ~ "/" ~ bmlFileName);
    addBml(p, rank, speed);
  }

  public BulletActor addTopBullet(BulletPool bullets, BulletTarget target, float xReverse = 1) {
    return bullets.addTopBullet(parserParam,
                                0, 0, PI, 0,
                                xReverse, 1, target,
                                prevWait, postWait);
  }

  public void clear() {
    parserParam = null;
  }
}

/**
 * Barrage manager (BulletMLs' loader).
 */
public class BarrageManager {
 private:
  static BulletMLParserTinyXML*[string][string] parser;
  static string BARRAGE_DIR_NAME = "barrage";

  public static void load() {
    auto dirs = dirEntries(BARRAGE_DIR_NAME, SpanMode.shallow);
    foreach (string dirName; dirs) {
      auto files = dirEntries(dirName, SpanMode.shallow);
      foreach (string fileName; files) {
        if (extension(fileName) != ".xml")
          continue;
        string dirBaseName = baseName(dirName);
        string fileBaseName = baseName(fileName);
        parser[dirBaseName][fileBaseName] = loadInstance(dirBaseName, fileBaseName);
      }
    }
  }

  private static BulletMLParserTinyXML* loadInstance(string dirName, string fileName) {
    string barrageName = dirName ~ "/" ~ fileName;
    Logger.info("Load BulletML: " ~ barrageName);
    parser[dirName][fileName] =
      BulletMLParserTinyXML_new(std.string.toStringz(BARRAGE_DIR_NAME ~ "/" ~ barrageName));
    BulletMLParserTinyXML_parse(parser[dirName][fileName]);
    return parser[dirName][fileName];
  }

  public static BulletMLParserTinyXML* getInstance(string dirName, string fileName) {
    return parser[dirName][fileName];
  }

  public static BulletMLParserTinyXML*[] getInstanceList(string dirName) {
    BulletMLParserTinyXML*[] pl;
    foreach (BulletMLParserTinyXML *p; parser[dirName]) {
      pl ~= p;
    }
    return pl;
  }

  public static void unload() {
    foreach (BulletMLParserTinyXML*[string] pa; parser) {
      foreach (BulletMLParserTinyXML *p; pa) {
        BulletMLParserTinyXML_delete(p);
      }
    }
  }
}
