/*************************************************************************
 *                                                                       *
 * Open Dynamics Engine, Copyright (C) 2001-2003 Russell L. Smith.       *
 * All rights reserved.  Email: russ@q12.org   Web: www.q12.org          *
 *                                                                       *
 * This library is free software; you can redistribute it and/or         *
 * modify it under the terms of EITHER:                                  *
 *   (1) The GNU Lesser General Public License as published by the Free  *
 *       Software Foundation; either version 2.1 of the License, or (at  *
 *       your option) any later version. The text of the GNU Lesser      *
 *       General Public License is included with this library in the     *
 *       file LICENSE.TXT.                                               *
 *   (2) The BSD-style license that is included with this library in     *
 *       the file LICENSE-BSD.TXT.                                       *
 *                                                                       *
 * This library is distributed in the hope that it will be useful,       *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the files    *
 * LICENSE.TXT and LICENSE-BSD.TXT for more details.                     *
 *                                                                       *
 *************************************************************************/
module ode.collision;

import ode.common;
import ode.collision;
import ode.contact;
//import ode.collision_space;
import ode.collision_trimesh;

extern(C):

/* ************************************************************************ */
/* general functions */

void dGeomDestroy (dGeomID);
void dGeomSetData (dGeomID, void *);
void *dGeomGetData (dGeomID);
void dGeomSetBody (dGeomID, dBodyID);
dBodyID dGeomGetBody (dGeomID);
void dGeomSetPosition (dGeomID, dReal x, dReal y, dReal z);
void dGeomSetRotation (dGeomID, ref dMatrix3 R);
void dGeomSetQuaternion (dGeomID, ref dQuaternion);
dReal * dGeomGetPosition (dGeomID);
dReal * dGeomGetRotation (dGeomID);
void dGeomGetQuaternion (dGeomID, ref dQuaternion result);
void dGeomGetAABB (dGeomID, ref dReal[6] aabb);
int dGeomIsSpace (dGeomID);
dSpaceID dGeomGetSpace (dGeomID);
int dGeomGetClass (dGeomID);
void dGeomSetCategoryBits (dGeomID, uint bits);
void dGeomSetCollideBits (dGeomID, uint bits);
uint dGeomGetCategoryBits (dGeomID);
uint dGeomGetCollideBits (dGeomID);
void dGeomEnable (dGeomID);
void dGeomDisable (dGeomID);
int dGeomIsEnabled (dGeomID);

/* ************************************************************************ */
/* collision detection */

int dCollide (dGeomID o1, dGeomID o2, int flags, dContactGeom *contact,
	      int skip);
//void dSpaceCollide (dSpaceID space, void *data, dNearCallback *callback);
void dSpaceCollide (dSpaceID space, void *data, void function (void *data, dGeomID o1, dGeomID o2) fp);
//void dSpaceCollide2 (dGeomID o1, dGeomID o2, void *data,
//		     dNearCallback *callback);
void dSpaceCollide2 (dGeomID o1, dGeomID o2, void *data,
		     void function (void *data, dGeomID o1, dGeomID o2) fp);

/* ************************************************************************ */
/* standard classes */

/* the maximum number of user classes that are supported */
enum {
  dMaxUserClasses = 4
};

/* class numbers - each geometry object needs a unique number */
enum {
  dSphereClass = 0,
  dBoxClass,
  dCCylinderClass,
  dCylinderClass,
  dPlaneClass,
  dRayClass,
  dGeomTransformClass,
  dTriMeshClass,

  dFirstSpaceClass,
  dSimpleSpaceClass = dFirstSpaceClass,
  dHashSpaceClass,
  dQuadTreeSpaceClass,
  dLastSpaceClass = dQuadTreeSpaceClass,

  dFirstUserClass,
  dLastUserClass = dFirstUserClass + dMaxUserClasses - 1,
  dGeomNumClasses
};


dGeomID dCreateSphere (dSpaceID space, dReal radius);
void dGeomSphereSetRadius (dGeomID sphere, dReal radius);
dReal dGeomSphereGetRadius (dGeomID sphere);
dReal dGeomSpherePointDepth (dGeomID sphere, dReal x, dReal y, dReal z);

dGeomID dCreateBox (dSpaceID space, dReal lx, dReal ly, dReal lz);
void dGeomBoxSetLengths (dGeomID box, dReal lx, dReal ly, dReal lz);
void dGeomBoxGetLengths (dGeomID box, ref dVector3 result);
dReal dGeomBoxPointDepth (dGeomID box, dReal x, dReal y, dReal z);

dGeomID dCreatePlane (dSpaceID space, dReal a, dReal b, dReal c, dReal d);
void dGeomPlaneSetParams (dGeomID plane, dReal a, dReal b, dReal c, dReal d);
void dGeomPlaneGetParams (dGeomID plane, ref dVector4 result);
dReal dGeomPlanePointDepth (dGeomID plane, dReal x, dReal y, dReal z);

dGeomID dCreateCCylinder (dSpaceID space, dReal radius, dReal length);
void dGeomCCylinderSetParams (dGeomID ccylinder, dReal radius, dReal length);
void dGeomCCylinderGetParams (dGeomID ccylinder, dReal *radius, dReal *length);
dReal dGeomCCylinderPointDepth (dGeomID ccylinder, dReal x, dReal y, dReal z);

dGeomID dCreateRay (dSpaceID space, dReal length);
void dGeomRaySetLength (dGeomID ray, dReal length);
dReal dGeomRayGetLength (dGeomID ray);
void dGeomRaySet (dGeomID ray, dReal px, dReal py, dReal pz,
		  dReal dx, dReal dy, dReal dz);
void dGeomRayGet (dGeomID ray, ref dVector3 start, ref dVector3 dir);

/*
 * Set/get ray flags that influence ray collision detection.
 * These flags are currently only noticed by the trimesh collider, because
 * they can make a major differences there.
 */
void dGeomRaySetParams (dGeomID g, int FirstContact, int BackfaceCull);
void dGeomRayGetParams (dGeomID g, int *FirstContact, int *BackfaceCull);
void dGeomRaySetClosestHit (dGeomID g, int closestHit);
int dGeomRayGetClosestHit (dGeomID g);

dGeomID dCreateGeomTransform (dSpaceID space);
void dGeomTransformSetGeom (dGeomID g, dGeomID obj);
dGeomID dGeomTransformGetGeom (dGeomID g);
void dGeomTransformSetCleanup (dGeomID g, int mode);
int dGeomTransformGetCleanup (dGeomID g);
void dGeomTransformSetInfo (dGeomID g, int mode);
int dGeomTransformGetInfo (dGeomID g);

/* ************************************************************************ */
/* utility functions */

void dClosestLineSegmentPoints (ref dVector3 a1, ref dVector3 a2,
				ref dVector3 b1, ref dVector3 b2,
				ref dVector3 cp1, ref dVector3 cp2);

int dBoxTouchesBox (ref dVector3 _p1, ref dMatrix3 R1,
		    ref dVector3 side1, ref dVector3 _p2,
		    ref dMatrix3 R2, ref dVector3 side2);

void dInfiniteAABB (dGeomID geom, ref dReal[6] aabb);
void dCloseODE();

/* ************************************************************************ */
/* custom classes */

alias void dGetAABBFn (dGeomID, ref dReal[6] aabb);
alias int dColliderFn (dGeomID o1, dGeomID o2,
			 int flags, dContactGeom *contact, int skip);
alias dColliderFn * dGetColliderFnFn (int num);
alias void dGeomDtorFn (dGeomID o);
alias int dAABBTestFn (dGeomID o1, dGeomID o2, ref dReal[6] aabb);

struct dGeomClass {
  int bytes;
  dGetColliderFnFn *collider;
  dGetAABBFn *aabb;
  dAABBTestFn *aabb_test;
  dGeomDtorFn *dtor;
};

int dCreateGeomClass (dGeomClass *classptr);
void * dGeomGetClassData (dGeomID);
dGeomID dCreateGeom (int classnum);

/* ************************************************************************ */
