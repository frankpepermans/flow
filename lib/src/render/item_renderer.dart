library flow.render.item_renderer;

import 'dart:async';

abstract class ItemRenderer<T> {

  T data;

  void setData(T newData) {
    if (newData != data) {
      data = newData;

      scheduleMicrotask(invalidateData);
    }
  }

  void clear();

  void draw(double w, double h);

  void connect(double fromX, double fromY, double toX, double toY);

  void invalidateData();
}