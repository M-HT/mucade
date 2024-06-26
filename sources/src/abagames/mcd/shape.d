/*
 * $Id: shape.d,v 1.1.1.1 2006/02/19 04:57:26 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.mcd.shape;

private import std.math;
version (USE_SIMD) {
  extern (C) {
    void diffuseSpectrumSimdHelper(float *posHist, int posIdx, float dfr);
  }
  enum{
    X = 0,
    Y,
    Z,
    A,
    XY = 2,
    XYZ = 3,
    XYZA = 4,
  }
}
private import opengl;
private import ode.ode;
private import abagames.util.vector;
private import abagames.util.sdl.displaylist;
private import abagames.util.ode.odeactor;
private import abagames.util.ode.world;
private import abagames.mcd.screen;
private import abagames.mcd.field;

/**
 * Vector style shape.
 * Handling mass and geom of a object.
 */
public interface Shape {
  public void addMass(dMass* m, Vector3 sizeScale = null, float massScale = 1);
  public void addGeom(OdeActor oa, dSpaceID sid, Vector3 sizeScale = null);
  public void recordLinePoints(LinePoint lp);
  public void drawShadow(LinePoint lp);
}

public class ShapeGroup: Shape {
 private:
  Shape[] shapes;

  public void addShape(Shape s) {
    shapes ~= s;
  }

  public void setMass(OdeActor oa, Vector3 sizeScale = null, float massScale = 1) {
    dMass m;
    dMassSetZero(&m);
    addMass(&m, sizeScale, massScale);
    oa.setMass(m);
  }

  public void setGeom(OdeActor oa, dSpaceID sid, Vector3 sizeScale = null) {
    addGeom(oa, sid, sizeScale);
  }

  public void addMass(dMass *m, Vector3 sizeScale = null, float massScale = 1) {
    foreach (Shape s; shapes)
      s.addMass(m, sizeScale, massScale);
  }

  public void addGeom(OdeActor oa, dSpaceID sid, Vector3 sizeScale = null) {
    foreach (Shape s; shapes)
      s.addGeom(oa, sid, sizeScale);
  }

  public void recordLinePoints(LinePoint lp) {
    foreach (Shape s; shapes)
      s.recordLinePoints(lp);
  }

  public void drawShadow(LinePoint lp) {
    foreach (Shape s; shapes)
      s.drawShadow(lp);
  }
}


public abstract class ShapeBase: Shape {
 protected:
  World world;
  Vector3 pos;
  Vector3 size;
  float mass = 1;
  float shapeBoxScale = 1;

  invariant() {
    if (pos) {
      assert(!std.math.isNaN(pos.x));
      assert(!std.math.isNaN(pos.y));
      assert(!std.math.isNaN(pos.z));
      assert(size.x >= 0);
      assert(size.y >= 0);
      assert(size.z >= 0);
      assert(mass >= 0);
    }
  }

  public void addMass(dMass* m, Vector3 sizeScale = null, float massScale = 1) {
    dMass sm;
    if (sizeScale) {
      dMassSetBox(&sm, 1, size.x * sizeScale.x, size.y * sizeScale.y, size.z * sizeScale.z);
      dMassTranslate(&sm, pos.x * sizeScale.x, pos.y * sizeScale.y, pos.z * sizeScale.z);
    } else {
      dMassSetBox(&sm, 1, size.x, size.y, size.z);
      dMassTranslate(&sm, pos.x, pos.y, pos.z);
    }
    dMassAdjust(&sm, mass * massScale);
    dMassAdd(m, &sm);
  }

  public void addGeom(OdeActor oa, dSpaceID sid, Vector3 sizeScale = null) {
    if (pos.x == 0 && pos.y == 0 && pos.z == 0) {
      dGeomID bg;
      if (sizeScale) {
        bg = dCreateBox(sid,
                        size.x * sizeScale.x * shapeBoxScale,
                        size.y * sizeScale.y * shapeBoxScale,
                        size.z * sizeScale.z * shapeBoxScale);
      } else {
        bg = dCreateBox(sid,
                        size.x * shapeBoxScale,
                        size.y * shapeBoxScale,
                        size.z * shapeBoxScale);
      }
      oa.addGeom(bg);
    } else {
      dGeomID tg = dCreateGeomTransform(sid);
      dGeomID bg;
      if (sizeScale) {
        bg = dCreateBox(cast(dSpaceID) 0,
                        size.x * sizeScale.x * shapeBoxScale,
                        size.y * sizeScale.y * shapeBoxScale,
                        size.z * sizeScale.z * shapeBoxScale);
        dGeomSetPosition(bg, pos.x * sizeScale.x, pos.y * sizeScale.y, pos.z * sizeScale.z);
      } else {
        bg = dCreateBox(cast(dSpaceID) 0,
                        size.x * shapeBoxScale,
                        size.y * shapeBoxScale,
                        size.z * shapeBoxScale);
        dGeomSetPosition(bg, pos.x, pos.y, pos.z);
      }
      dGeomTransformSetGeom(tg, bg);
      oa.addGeom(tg);
      oa.addTransformedGeom(bg);
    }
  }

  public abstract void recordLinePoints(LinePoint lp);
  public abstract void drawShadow(LinePoint lp);
}

public class Square: ShapeBase {
 private:

  public this(World world, float mass, float px, float py, float sx, float sy) {
    this.world = world;
    this.mass = mass;
    pos = new Vector3(px, py, 0);
    size = new Vector3(sx, sy, 1);
  }

  public this(World world, float mass, float px, float py, float pz,
              float sx, float sy, float sz) {
    this.world = world;
    this.mass = mass;
    pos = new Vector3(px, py, pz);
    size = new Vector3(sx, sy, sz);
  }

  public override void recordLinePoints(LinePoint lp) {
    lp.setPos(pos);
    lp.setSize(size);
    lp.record(-1, -1, 0);
    lp.record( 1, -1, 0);
    lp.record( 1, -1, 0);
    lp.record( 1,  1, 0);
    lp.record( 1,  1, 0);
    lp.record(-1,  1, 0);
    lp.record(-1,  1, 0);
    lp.record(-1, -1, 0);
  }

  public override void drawShadow(LinePoint lp) {
    lp.setPos(pos);
    lp.setSize(size);
    if (!lp.setShadowColor())
      return;
    glBegin(GL_TRIANGLE_FAN);
    lp.vertex(-1, -1, 0);
    lp.vertex( 1, -1, 0);
    lp.vertex( 1,  1, 0);
    lp.vertex(-1,  1, 0);
    glEnd();
  }
}

public class Sphere: ShapeBase {
 private:

  public this(World world, float mass, float px, float py, float rad) {
    this.world = world;
    this.mass = mass;
    pos = new Vector3(px, py, 0);
    size = new Vector3(rad, rad, rad);
  }

  public override void addGeom(OdeActor oa, dSpaceID sid, Vector3 sizeScale = null) {
    if (pos.x == 0 && pos.y == 0 && pos.z == 0) {
      dGeomID bg;
      if (sizeScale) {
        bg = dCreateSphere(sid,
                           size.x * sizeScale.x * shapeBoxScale);
      } else {
        bg = dCreateSphere(sid,
                           size.x * shapeBoxScale);
      }
      oa.addGeom(bg);
    } else {
      dGeomID tg = dCreateGeomTransform(sid);
      dGeomID bg;
      if (sizeScale) {
        bg = dCreateSphere(cast(dSpaceID) 0,
                           size.x * sizeScale.x * shapeBoxScale);
        dGeomSetPosition(bg, pos.x * sizeScale.x, pos.y * sizeScale.y, pos.z * sizeScale.z);
      } else {
        bg = dCreateSphere(cast(dSpaceID) 0,
                           size.x * shapeBoxScale);
        dGeomSetPosition(bg, pos.x, pos.y, pos.z);
      }
      dGeomTransformSetGeom(tg, bg);
      oa.addGeom(tg);
      oa.addTransformedGeom(bg);
    }
  }

  public override void recordLinePoints(LinePoint lp) {
    lp.setPos(pos);
    lp.setSize(size);
    lp.record(-1, -1, 0);
    lp.record( 1, -1, 0);
    lp.record( 1, -1, 0);
    lp.record( 1,  1, 0);
    lp.record( 1,  1, 0);
    lp.record(-1,  1, 0);
    lp.record(-1,  1, 0);
    lp.record(-1, -1, 0);
  }

  public override void drawShadow(LinePoint lp) {
    lp.setPos(pos);
    lp.setSize(size);
    if (!lp.setShadowColor())
      return;
    glBegin(GL_TRIANGLE_FAN);
    lp.vertex(-1, -1, 0);
    lp.vertex( 1, -1, 0);
    lp.vertex( 1,  1, 0);
    lp.vertex(-1,  1, 0);
    glEnd();
  }
}

public class Triangle: ShapeBase {
 private:

  public this(World world, float mass, float px, float py, float sx, float sy) {
    this.world = world;
    this.mass = mass;
    pos = new Vector3(px, py, 0);
    size = new Vector3(sx, sy, 1);
    shapeBoxScale = 1;
  }

  public override void recordLinePoints(LinePoint lp) {
    lp.setPos(pos);
    lp.setSize(size);
    lp.record( 0,  1, 0);
    lp.record( 1, -1, 0);
    lp.record( 1, -1, 0);
    lp.record(-1, -1, 0);
    lp.record(-1, -1, 0);
    lp.record( 0,  1, 0);
  }

  public override void drawShadow(LinePoint lp) {
    lp.setPos(pos);
    lp.setSize(size);
    if (!lp.setShadowColor())
      return;
    glBegin(GL_TRIANGLE_FAN);
    lp.vertex( 0,  1, 0);
    lp.vertex( 1, -1, 0);
    lp.vertex(-0, -1, 0);
    glEnd();
  }
}

public class Box: ShapeBase {
 private:

  public this(World world, float mass, float px, float py, float pz, float sx, float sy, float sz) {
    this.world = world;
    this.mass = mass;
    pos = new Vector3(px, py, pz);
    size = new Vector3(sx, sy, sz);
  }

  public override void recordLinePoints(LinePoint lp) {
    lp.setPos(pos);
    lp.setSize(size);
    lp.record(-1, -1, -1);
    lp.record( 1, -1, -1);
    lp.record( 1, -1, -1);
    lp.record( 1,  1, -1);
    lp.record( 1,  1, -1);
    lp.record(-1,  1, -1);
    lp.record(-1,  1, -1);
    lp.record(-1, -1, -1);

    lp.record(-1, -1,  1);
    lp.record( 1, -1,  1);
    lp.record( 1, -1,  1);
    lp.record( 1,  1,  1);
    lp.record( 1,  1,  1);
    lp.record(-1,  1,  1);
    lp.record(-1,  1,  1);
    lp.record(-1, -1,  1);

    lp.record(-1, -1,  1);
    lp.record(-1, -1, -1);
    lp.record( 1, -1,  1);
    lp.record( 1, -1, -1);
    lp.record( 1,  1,  1);
    lp.record( 1,  1, -1);
    lp.record(-1,  1,  1);
    lp.record(-1,  1, -1);
  }

  public override void drawShadow(LinePoint lp) {
    lp.setPos(pos);
    lp.setSize(size);
    if (!lp.setShadowColor())
      return;
    glBegin(GL_QUADS);
    lp.vertex(-1, -1, -1);
    lp.vertex( 1, -1, -1);
    lp.vertex( 1,  1, -1);
    lp.vertex(-1,  1, -1);

    lp.vertex(-1, -1,  1);
    lp.vertex( 1, -1,  1);
    lp.vertex( 1,  1,  1);
    lp.vertex(-1,  1,  1);

    lp.vertex(-1, -1, -1);
    lp.vertex( 1, -1, -1);
    lp.vertex( 1, -1,  1);
    lp.vertex(-1, -1,  1);

    lp.vertex(-1,  1, -1);
    lp.vertex( 1,  1, -1);
    lp.vertex( 1,  1,  1);
    lp.vertex(-1,  1,  1);

    lp.vertex(-1, -1, -1);
    lp.vertex(-1,  1, -1);
    lp.vertex(-1,  1,  1);
    lp.vertex(-1, -1,  1);

    lp.vertex( 1, -1, -1);
    lp.vertex( 1,  1, -1);
    lp.vertex( 1,  1,  1);
    lp.vertex( 1, -1,  1);
    glEnd();
  }
}

public class LinePoint {
 private:
  static const int HISTORY_MAX = 40;
  Field field;
  version (USE_SIMD) {
    float[] pos;
    float[][HISTORY_MAX] posHist;
  } else {
    Vector3[] pos;
    Vector3[][] posHist;
  }
  int posIdx, histIdx;
  Vector3 basePos, baseSize;
  GLfloat[16] m;
  bool isFirstRecord;
  float spectrumColorR, spectrumColorG, spectrumColorB;
  float spectrumColorRTrg, spectrumColorGTrg, spectrumColorBTrg;
  float spectrumLength;
  float _alpha, _alphaTrg;
  bool _enableSpectrumColor;

  invariant() {
    if (pos) {
      assert(posIdx >= 0);
      assert(histIdx >= 0 && histIdx < HISTORY_MAX);
      assert(spectrumLength >= 0 && spectrumLength <= 1);
      assert(_alpha >= 0 && _alpha <= 1);
      assert(spectrumColorRTrg >= 0 && spectrumColorRTrg <= 1);
      assert(spectrumColorGTrg >= 0 && spectrumColorGTrg <= 1);
      assert(spectrumColorBTrg >= 0 && spectrumColorBTrg <= 1);
      assert(spectrumColorR >= 0 && spectrumColorR <= 1);
      assert(spectrumColorG >= 0 && spectrumColorG <= 1);
      assert(spectrumColorB >= 0 && spectrumColorB <= 1);
      for (int i = 0; i < posIdx; i++) {
        version (USE_SIMD) {
          assert(!std.math.isNaN(pos[i*XYZA+X]));
          assert(!std.math.isNaN(pos[i*XYZA+Y]));
          assert(!std.math.isNaN(pos[i*XYZA+Z]));
        } else {
          assert(!std.math.isNaN(pos[i].x));
          assert(!std.math.isNaN(pos[i].y));
          assert(!std.math.isNaN(pos[i].z));
        }
      }
    }
  }

  public this(Field field, int pointMax = 8) {
    init();
    this.field = field;
    version (USE_SIMD) {
      pos.length = pointMax*XYZA;
      foreach (ref float[] pp; posHist) {
        pp.length = pointMax*XYZA;
      }
    } else {
      pos = new Vector3[pointMax];
      posHist = new Vector3[][HISTORY_MAX];
      foreach (ref Vector3 p; pos)
          p = new Vector3;
      foreach (ref Vector3[] pp; posHist) {
        pp = new Vector3[pointMax];
        foreach (ref Vector3 p; pp)
          p = new Vector3;
      }
    }
    spectrumColorRTrg = spectrumColorGTrg = spectrumColorBTrg = 0;
    spectrumLength = 0;
    _alpha = _alphaTrg = 1;
  }

  public void init() {
    posIdx = 0;
    histIdx = 0;
    isFirstRecord = true;
    spectrumColorR = spectrumColorG = spectrumColorB = 0;
    _enableSpectrumColor = true;
  }

  public void setSpectrumParams(float r, float g, float b, float length) {
    spectrumColorRTrg = r;
    spectrumColorGTrg = g;
    spectrumColorBTrg = b;
    spectrumLength = length;
  }

  public void beginRecord() {
    posIdx = 0;
    glGetFloatv(GL_MODELVIEW_MATRIX, m.ptr);
  }

  public void setPos(Vector3 p) {
    basePos = p;
  }

  public void setSize(Vector3 s) {
    baseSize = s;
  }

  public void record(float ox, float oy, float oz) {
    float tx, ty, tz;
    calcTranslatedPos(tx, ty, tz, ox, oy, oz);
    version (USE_SIMD) {
      pos[posIdx*XYZA+X] = tx;
      pos[posIdx*XYZA+Y] = ty;
      pos[posIdx*XYZA+Z] = tz;
    } else {
      pos[posIdx].x = tx;
      pos[posIdx].y = ty;
      pos[posIdx].z = tz;
    }
    posIdx++;
  }

  public void endRecord() {
    histIdx++;
    if (histIdx >= HISTORY_MAX)
      histIdx = 0;
    if (isFirstRecord) {
      isFirstRecord = false;
      for (int j = 0; j < HISTORY_MAX; j++) {
        version (USE_SIMD) {
          posHist[j][0 .. posIdx*XYZA] = pos[0 .. posIdx*XYZA];
        } else {
          for (int i = 0; i < posIdx; i++) {
            posHist[j][i].x = pos[i].x;
            posHist[j][i].y = pos[i].y;
            posHist[j][i].z = pos[i].z;
          }
        }
      }
    } else {
      version (USE_SIMD) {
        posHist[histIdx][0 .. posIdx*XYZA] = pos[0 .. posIdx*XYZA];
      } else {
        for (int i = 0; i < posIdx; i++) {
          posHist[histIdx][i].x = pos[i].x;
          posHist[histIdx][i].y = pos[i].y;
          posHist[histIdx][i].z = pos[i].z;
        }
      }
    }
    diffuseSpectrum();
    if (_enableSpectrumColor) {
      spectrumColorR += (spectrumColorRTrg - spectrumColorR) * 0.1f;
      spectrumColorG += (spectrumColorGTrg - spectrumColorG) * 0.1f;
      spectrumColorB += (spectrumColorBTrg - spectrumColorB) * 0.1f;
    } else {
      spectrumColorR *= 0.9f;
      spectrumColorG *= 0.9f;
      spectrumColorB *= 0.9f;
    }
    _alpha += (_alphaTrg - _alpha) * 0.05f;
  }

  private void diffuseSpectrum() {
    const float dfr = 0.01f;
    for (int j = 0; j < HISTORY_MAX; j++) {
      version (USE_SIMD) {
        diffuseSpectrumSimdHelper(posHist[j].ptr, posIdx, dfr);
      } else {
        for (int i = 0; i < posIdx; i += 2) {
          float ox = posHist[j][i].x - posHist[j][i+1].x;
          float oy = posHist[j][i].y - posHist[j][i+1].y;
          float oz = posHist[j][i].z - posHist[j][i+1].z;
          posHist[j][i].x += ox * dfr;
          posHist[j][i].y += oy * dfr;
          posHist[j][i].z += oz * dfr;
          posHist[j][i+1].x -= ox * dfr;
          posHist[j][i+1].y -= oy * dfr;
          posHist[j][i+1].z -= oz * dfr;
        }
      }
    }
  }

  public void vertex(float ox, float oy, float oz) {
    float tx, ty, tz;
    calcTranslatedPos(tx, ty, tz, ox, oy, oz);
    glVertex3f(tx, ty, tz);
  }

  private void calcTranslatedPos(ref float tx, ref float ty, ref float tz,
                                 float ox, float oy, float oz) {
    float x = basePos.x + baseSize.x / 2 * ox;
    float y = basePos.y + baseSize.y / 2 * oy;
    float z = basePos.z + baseSize.z / 2 * oz;
    tx = m[0] * x + m[4] * y + m[8] * z + m[12];
    ty = m[1] * x + m[5] * y + m[9] * z + m[13];
    tz = m[2] * x + m[6] * y + m[10] * z + m[14];
  }

  public bool setShadowColor() {
    if (spectrumColorR + spectrumColorG + spectrumColorB < 0.1f)
      return false;
    Screen.setColor(spectrumColorR * 0.3f, spectrumColorG * 0.3f, spectrumColorB * 0.3f);
    return true;
  }

  public void draw() {
    if (isFirstRecord)
      return;
    glBegin(GL_LINES);
    for (int i = 0; i < posIdx; i += 2) {
      version (USE_SIMD) {
        Screen.drawLine(pos[i*XYZA+X], pos[i*XYZA+Y], pos[i*XYZA+Z],
                        pos[(i + 1)*XYZA+X], pos[(i + 1)*XYZA+Y], pos[(i + 1)*XYZA+Z], _alpha);
      } else {
        Screen.drawLine(pos[i].x, pos[i].y, pos[i].z,
                        pos[i + 1].x, pos[i + 1].y, pos[i + 1].z, _alpha);
      }
    }
    glEnd();
  }

  public void drawWithSpectrumColor() {
    if (isFirstRecord)
      return;
    if (spectrumColorR + spectrumColorG + spectrumColorB < 0.1f)
      return;
    Screen.setColor(spectrumColorR, spectrumColorG, spectrumColorB);
    glBegin(GL_LINE_STRIP);
    for (int i = 0; i < posIdx; i++) {
      version (USE_SIMD) {
        glVertex3f(pos[i*XYZA+X], pos[i*XYZA+Y], pos[i*XYZA+Z]);
      } else {
        glVertex3f(pos[i].x, pos[i].y, pos[i].z);
      }
    }
    glEnd();
  }

  version (USE_SIMD) {
    private float vectorDist(float* v1, float* v2) {
      float ax = fabs(v1[X] - v2[X]);
      float ay = fabs(v1[Y] - v2[Y]);
      float az = fabs(v1[Z] - v2[Z]);
      float axy;
      if (ax > ay)
        axy = ax + ay / 2;
      else
        axy = ay + ax / 2;
      if (axy > az)
        return axy + az / 2;
      else
        return az + axy / 2;
    }
  }

  public void drawSpectrum() {
    if (spectrumLength <= 0 || isFirstRecord)
      return;
    if (spectrumColorR + spectrumColorG + spectrumColorB < 0.1f)
      return;
    glBegin(GL_QUADS);
    float al = 0.5f, bl = 0.5f;
    float hif, nhif;
    float hio = 5.5f;
    nhif = histIdx;
    for (int j = 0; j < 10 * spectrumLength; j++) {
      Screen.setColor((spectrumColorR + (1.0f - spectrumColorR) * bl) * al,
                      (spectrumColorG + (1.0f - spectrumColorG) * bl) * al,
                      (spectrumColorB + (1.0f - spectrumColorB) * bl) * al,
                      al);
      hif = nhif;
      nhif = hif - hio;
      if (nhif < 0)
        nhif += HISTORY_MAX;
      int hi = cast(int) hif;
      int nhi = cast(int) nhif;
      version (USE_SIMD) {
        if (vectorDist(posHist[hi].ptr, posHist[nhi].ptr) < 8) {
          for (int i = 0; i < posIdx; i += 2) {
            glVertex3f(posHist[hi][i*XYZA+X], posHist[hi][i*XYZA+Y], posHist[hi][i*XYZA+Z]);
            glVertex3f(posHist[hi][(i+1)*XYZA+X], posHist[hi][(i+1)*XYZA+Y], posHist[hi][(i+1)*XYZA+Z]);
            glVertex3f(posHist[nhi][(i+1)*XYZA+X], posHist[nhi][(i+1)*XYZA+Y], posHist[nhi][(i+1)*XYZA+Z]);
            glVertex3f(posHist[nhi][i*XYZA+X], posHist[nhi][i*XYZA+Y], posHist[nhi][i*XYZA+Z]);
          }
        }
      } else {
        if (posHist[hi][0].dist(posHist[nhi][0]) < 8) {
          for (int i = 0; i < posIdx; i += 2) {
            glVertex3f(posHist[hi][i].x, posHist[hi][i].y, posHist[hi][i].z);
            glVertex3f(posHist[hi][i+1].x, posHist[hi][i+1].y, posHist[hi][i+1].z);
            glVertex3f(posHist[nhi][i+1].x, posHist[nhi][i+1].y, posHist[nhi][i+1].z);
            glVertex3f(posHist[nhi][i].x, posHist[nhi][i].y, posHist[nhi][i].z);
          }
        }
      }
      al *= 0.88f * spectrumLength;
      bl *= 0.88f * spectrumLength;
    }
    glEnd();
  }

  public float alpha(float v) {
    return _alpha = v;
  }

  public float alphaTrg(float v) {
    return _alphaTrg = v;
  }

  public bool enableSpectrumColor(bool v) {
    return _enableSpectrumColor = v;
  }
}

public interface Drawable {
  public void draw();
}

public class EyeShape: Drawable {
  public void draw() {
    Screen.setColor(1.0f, 0, 0);
    glBegin(GL_LINE_LOOP);
    glVertex3f(-0.5, 0.5, 0);
    glVertex3f(-0.3, 0.5, 0);
    glVertex3f(-0.3, 0.3, 0);
    glVertex3f(-0.5, 0.3, 0);
    glEnd();
    glBegin(GL_LINE_LOOP);
    glVertex3f(0.5, 0.5, 0);
    glVertex3f(0.3, 0.5, 0);
    glVertex3f(0.3, 0.3, 0);
    glVertex3f(0.5, 0.3, 0);
    glEnd();
    Screen.setColor(0.8f, 0.4f, 0.4f);
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(-0.5, 0.5, 0);
    glVertex3f(-0.3, 0.5, 0);
    glVertex3f(-0.3, 0.3, 0);
    glVertex3f(-0.5, 0.3, 0);
    glEnd();
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(0.5, 0.5, 0);
    glVertex3f(0.3, 0.5, 0);
    glVertex3f(0.3, 0.3, 0);
    glVertex3f(0.5, 0.3, 0);
    glEnd();
  }
}

public class CenterShape: Drawable {
  public void draw() {
    Screen.setColor(0.6f, 1.0f, 0.5f);
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(-0.2, -0.2, 0);
    glVertex3f( 0.2, -0.2, 0);
    glVertex3f( 0.2,  0.2, 0);
    glVertex3f(-0.2,  0.2, 0);
    glEnd();
    Screen.setColor(0.4f, 0.8f, 0.2f);
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(-0.6, 0.6, 0);
    glVertex3f(-0.3, 0.6, 0);
    glVertex3f(-0.3, 0.3, 0);
    glVertex3f(-0.6, 0.3, 0);
    glEnd();
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(0.6, 0.6, 0);
    glVertex3f(0.3, 0.6, 0);
    glVertex3f(0.3, 0.3, 0);
    glVertex3f(0.6, 0.3, 0);
    glEnd();
  }
}
