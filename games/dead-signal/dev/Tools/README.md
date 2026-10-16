# Offline authoring tools

Run from the kit root with Lune:

```text
lune run Tools/build-places.luau
```

This rebuilds the four current place files from the included v1.7.0 rollback files plus `Source/Runtime`, then reopens them. It preserves each place's distinct PlaceConfig and creator-owned asset references. The helper in `Tests/Support` handles offline instance transforms; it does not run Studio simulation.

`AnatomyMaterials.luau` bakes the two added material variants using texture references already present in the art. Material map/BaseMaterial properties require authoring permissions, so this helper is never called by a live game script.

With Python, NumPy and SciPy installed:

```text
python Tools/check-geometry.py
```

The checker uses exact polygon ground regions and projected, radius-inflated oriented collider hulls. It checks interaction and corridor-portal approaches and samples complete corridor centerlines with gates open. It does not simulate vertical navigation, physics, crowd contact, actual door progression or safe spots.
