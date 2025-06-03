@JS()
library react_dnd;

import 'dart:js_interop';

//@JS('ReactDnD_DndProvider')
//external get DndProvider;
//
//@JS('ReactDnDHTML5Backend_default')
//external get HTML5Backend;
//
//@JS('ReactDnD_useDrag')
//external get useDrag;

@JS('ReactDnD_useDrag')
external get useDrag;

@JS()
external get ReactDnD_DndProvider;

@JS('ReactDnDHTML5Backend_default')
external get HTML5Backend;

//var DndProvider = ReactJsComponentFactoryProxy(ReactDnD_DndProvider);
var DndProvider = null;

//@JS()
//external ReactDnD_DndContext(dynamic obj);
//
//@JS()
//external ReactDnD_createDndContext(dynamic obj);
//
//@JS()
//external ReactDnD_DragPreviewImage(dynamic obj);
//
//
//@JS()
//external ReactDnD_useDrop(dynamic obj);
//
//@JS()
//external ReactDnD_useDragLayer(dynamic obj);
//
//@JS()
//external ReactDnD_DragSource(dynamic obj);
//
//@JS()
//external ReactDnD_DropTarget(dynamic obj);
//
//@JS()
//external ReactDnD_DragLayer(dynamic obj);
//
//@JS()
//external ReactDnDHTML5Backend_NativeTypes(dynamic obj);
//
//@JS()
//external ReactDnDHTML5Backend_getEmptyImage(dynamic obj);
