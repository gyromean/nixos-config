#!/usr/bin/env python

import sys, textwrap
from PyQt6.QtWidgets import QApplication, QMainWindow, QGraphicsView, QGraphicsScene, QGraphicsItemGroup
from PyQt6.QtGui import QPainter, QPen, QBrush, QColor, QFont, QPainterPath, QFontMetrics
from PyQt6.QtCore import Qt, QRectF, QPointF
from PyQt6.QtNetwork import QLocalSocket

colors = {name: QColor(*val) for name, val in {
  'background': (0x2e, 0x34, 0x40),
  'white': (0xec, 0xef, 0xf4),
  'blue': (0x88, 0xc0, 0xd0),
  'dim': (0x4c, 0x56, 0x6a),
  # 'yellow': (0xeb, 0xcb, 0x8b),
  # 'red': (0xbf, 0x61, 0x6a),
}.items()}

active_color = colors['dim']
completed_color = colors['blue']

LINE_CHAR_LIMIT = 40
CORNER_RADIUS = 30
BORDER_WIDTH = 8
BORDER_WIDTH = 4
BORDER_INNER_SPACE = 20
BORDER_OUTER_SPACE = 20
FONT_WEIGHT = 600

# BEZIER_CONTROL_LENGTH = 160
# HORIZONTAL_MARGIN = 250
# VERTICAL_MARGIN = 50

BEZIER_CONTROL_LENGTH = 80
HORIZONTAL_MARGIN = 160
VERTICAL_MARGIN = 40

SCALE_FACTOR = 1.05

class RenderedNode:
  def __init__(self, text, scene, is_completed):
    self.associated_items = []
    self.color = active_color if not is_completed else completed_color
    self.text = text
    self.lines = textwrap.wrap(text, LINE_CHAR_LIMIT)
    self.processed_text = '\n'.join(self.lines)
    self.group = QGraphicsItemGroup()

    text_item = scene.addText(self.processed_text, QFont(['Sans-serif'], 15, FONT_WEIGHT))
    text_item.setDefaultTextColor(self.color)
    self.group.addToGroup(text_item)

    delta = BORDER_WIDTH / 2 + BORDER_INNER_SPACE

    bounding_rect = self.group.boundingRect()
    x = bounding_rect.x() - delta
    y = bounding_rect.y() - delta
    w = bounding_rect.width() + 2 * delta
    h = bounding_rect.height() + 2 * delta

    border_path = QPainterPath()
    border_path.addRoundedRect(x, y, w, h, CORNER_RADIUS, CORNER_RADIUS)
    border_item = scene.addPath(border_path, pen=QPen(QColor(self.color), BORDER_WIDTH))
    self.group.addToGroup(border_item)

    self.width = w + BORDER_WIDTH
    self.height = h + BORDER_WIDTH

  def render_top_left(self, scene, x, y):
    self.render(scene, x, y + self.height / 2)

  def render(self, scene, x, y):
    self.x = x
    self.y = y
    x += BORDER_WIDTH + BORDER_INNER_SPACE # must compensate because the "origin" is at the top left of the text
    y += BORDER_WIDTH + BORDER_INNER_SPACE
    self.group.setPos(x, y - self.height / 2)
    scene.addItem(self.group)

class RenderedEdge:
  def __init__(self, parent, child, is_completed):
    self.is_completed = is_completed
    self.color = active_color if not is_completed else completed_color
    x_a = parent.x + parent.width + BORDER_OUTER_SPACE
    y_a = parent.y
    x_b = child.x - BORDER_OUTER_SPACE
    y_b = child.y
    self.path = QPainterPath()
    self.path.moveTo(x_a, y_a)
    self.path.cubicTo(x_a + BEZIER_CONTROL_LENGTH, y_a, x_b - BEZIER_CONTROL_LENGTH, y_b, x_b, y_b)

  def render(self, scene):
    self.item = scene.addPath(self.path, pen=QPen(QColor(self.color), BORDER_WIDTH, cap=Qt.PenCapStyle.RoundCap))
    if self.is_completed:
      self.item.setZValue(1)

class Tree:
  class Node:
    def __init__(self, text, is_completed, parent=None):
      self.text = text
      self.is_completed = is_completed

      self.parent = parent
      self.children = []

      self.rendered_node = None
      self.rendered_edge = None
      self.x = 0 # top left corner of subtree bounding box
      self.y = 0
      self.bb_width = 0
      self.bb_height = 0

    def __repr__(self):
      ret = []
      ret.append(f'{self.text = }')
      ret.append(f'{self.is_completed = }')
      ret.append(f'{self.parent is not None = }')
      ret.append(f'{len(self.children) = }')
      ret.append(f'{self.rendered_node = }')
      ret.append(f'{self.rendered_edge = }')
      return '\n'.join(ret)

  def __init__(self, lines, scene, view):
    self.scene = scene
    self.view = view
    if isinstance(lines, str):
      lines = lines.splitlines()
    lines = map(str.rstrip, lines)
    lines = filter(len, lines)
    self.lines = list(lines)

    self.build_tree()

  def build_tree_rec(self, parent=None):
    level, text, is_completed = self.entries[self.entry_index]
    node = Tree.Node(text, is_completed, parent)
    self.entry_index += 1
    while self.entry_index < len(self.entries) \
        and self.entries[self.entry_index][0] > level:
      node.children.append(self.build_tree_rec(node))
    if len(node.children): # has children -> derive is_completed from them
      node.is_completed = True
      for child in node.children:
        if child.is_completed == False:
          node.is_completed = False
          break
    self.nodes.append(node)
    return node

  def build_tree(self):
    self.build_entries()
    self.nodes = []
    if len(self.entries) == 0:
      return
    # process root
    self.entry_index = 0
    self.root = self.build_tree_rec()

  def build_entries(self):
    self.entries = []
    for text in self.lines:
      spaces = len(text) - len(text.lstrip(' '))
      level = spaces
      is_completed = text[spaces] == '-'
      text = text[spaces + is_completed:]
      self.entries.append((level, text, is_completed))

  def calculate_layout_rec(self, node, x, y):
    node.rendered_node = RenderedNode(node.text, self.scene, node.is_completed)
    node.x = x
    node.y = y
    if len(node.children) == 0: # leaf
      node.bb_width = node.rendered_node.width
      node.bb_height = node.rendered_node.height
      return

    x += node.rendered_node.width + HORIZONTAL_MARGIN
    bb_width = 0
    bb_height = -VERTICAL_MARGIN
    for child in node.children:
      self.calculate_layout_rec(child, x, y)
      dy = child.bb_height + VERTICAL_MARGIN
      y += dy
      bb_height += dy
      bb_width = max(bb_width, child.bb_width)
    bb_width += node.rendered_node.width + HORIZONTAL_MARGIN
    node.bb_width = bb_width
    node.bb_height = bb_height

  def calculate_layout(self):
    self.calculate_layout_rec(self.root, 0, 0)

  def render_rec(self, node):
    node.rendered_node.render(self.scene, node.x, node.y + node.bb_height / 2)
    if node.parent:
      node.rendered_edge = RenderedEdge(node.parent.rendered_node, node.rendered_node, node.is_completed)
      node.rendered_edge.render(self.scene)
    for child in node.children:
      self.render_rec(child)

  def render(self):
    if len(self.entries) == 0:
      return
    self.calculate_layout()
    self.render_rec(self.root)

  def remove_node_and_edge(self, node):
    self.scene.removeItem(node.rendered_node.group)
    if node.rendered_edge is not None:
      self.scene.removeItem(node.rendered_edge.item)
    for child in node.children:
      self.remove_node_and_edge(child)

  def remove(self):
    if len(self.entries) == 0:
      return
    self.remove_node_and_edge(self.root)

  @staticmethod
  def node_distance_from_center(node, view):
    rn = node.rendered_node
    x = rn.x + rn.width / 2
    y = rn.y
    real_pos = view.mapFromScene(x, y)

    x = real_pos.x()
    y = real_pos.y()
    c_x = view.width() / 2
    c_y = view.height() / 2
    d_x = c_x - x
    d_y = c_y - y

    return (d_x**2 + d_y**2)**.5

  def nodes_sorted_from_center(self, view):
    ret = [(node, Tree.node_distance_from_center(node, view)) for node in self.nodes]
    ret.sort(key=lambda x: x[1])
    return [node for node, _ in ret]

  def update(self, original):
    self.render()
    if len(original.nodes) == 0:
      return

    original.remove()
    for original_node in original.nodes_sorted_from_center(self.view):
      for new_node in self.nodes:
        if new_node.text == original_node.text:
          orig_x = original_node.x
          orig_y = original_node.y + original_node.bb_height / 2
          new_x = new_node.x
          new_y = new_node.y + new_node.bb_height / 2
          dx = orig_x - new_x
          dy = orig_y - new_y
          self.view.translate(dx, dy)
          return

# ------------------------- QT -------------------------

class GraphicsView(QGraphicsView):
  def __init__(self, scene, *a):
    super().__init__(scene, *a)
    self.scene = scene
    self.pressed = False
    self.setTransformationAnchor(QGraphicsView.ViewportAnchor.NoAnchor) # translate doesn't work otherwise, https://stackoverflow.com/questions/14610568/how-to-use-the-qgraphicsviews-translate-function
    self.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
    self.setVerticalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
    self.keep_centered = True

  # https://stackoverflow.com/questions/55007339/allow-qgraphicsview-to-move-outside-scene
  def updateSceneRect(self):
    bounding_rect = self.scene.itemsBoundingRect()
    scaled_by = self.transform().m11()
    bounding_rect.adjust(-self.width() / scaled_by, # take scaling into consideration
                         -self.height() / scaled_by,
                         self.width() / scaled_by,
                         self.height() / scaled_by)
    self.setSceneRect(bounding_rect)

  def mousePressEvent(self, event):
    self.prev_pos = event.pos()
    self.pressed = True

  def paintEvent(self, event): # triggers even when resizing
    # import random
    # print('paint ', random.randint(1, 5) * '-')
    self.updateSceneRect()
    super().paintEvent(event)

  def resizeEvent(self, event):
    if self.keep_centered:
      self.center()
    super().resizeEvent(event)

  def wheelEvent(self, event):
    x = int(event.position().x())
    y = int(event.position().y())
    old_pos = self.mapToScene(x, y)

    if event.angleDelta().y() == 0:
      return
    elif event.angleDelta().y() > 0:
      self.scale(SCALE_FACTOR, SCALE_FACTOR)
    else:
      self.scale(1 / SCALE_FACTOR, 1 / SCALE_FACTOR)

    new_pos = self.mapToScene(x, y)
    delta_pos = new_pos - old_pos
    self.translate(delta_pos.x(), delta_pos.y())
    self.keep_centered = False

  def center(self):
    bounding_rect = self.scene.itemsBoundingRect()
    bounding_rect.adjust(-100, -100, 100, 100) # add some margins
    self.fitInView(bounding_rect, Qt.AspectRatioMode.KeepAspectRatio)
    self.keep_centered = True

  def keyPressEvent(self, event):
    if event.key() == ord('R'):
      self.center()

    if event.key() == ord('Q'):
      global app
      app.exit()

  def mouseMoveEvent(self, event):
    if not (event.buttons() & Qt.MouseButton.LeftButton):
      return
    pos_delta = event.pos() - self.prev_pos
    self.prev_pos = event.pos()
    scaled_by = self.transform().m11()
    self.translate(pos_delta.x() / scaled_by, pos_delta.y() / scaled_by)
    self.keep_centered = False

class MainWindow(QMainWindow):
  def __init__(self):
    super().__init__()

    self.setWindowTitle("Drawing App")

    self.scene = QGraphicsScene()
    self.view = GraphicsView(self.scene)
    self.view.setRenderHint(QPainter.RenderHint.Antialiasing)
    self.view.setDragMode(QGraphicsView.DragMode.ScrollHandDrag)
    self.setCentralWidget(self.view)
    self.scene.setBackgroundBrush(QColor(colors['background']))

    self.sock = MySocket(self.scene, self.view)
    self.sock.connect(sys.argv[1])

    self.view.tree = Tree('', self.scene, self.view)
    self.view.tree.render()

class MySocket(QLocalSocket):
  def __init__(self, scene, view):
    super().__init__()
    self.scene = scene
    self.view = view

  def connect(self, name):
    self.connectToServer(name)
    self.readyRead.connect(self.read_handler)
    self.errorOccurred.connect(self.error_handler)

  def read_handler(self):
    data = self.readData(10000)
    string = data.decode(encoding='UTF-8')
    new_t = Tree(string, self.scene, self.view)
    new_t.update(self.view.tree)
    if self.view.keep_centered:
      self.view.center()
    self.view.tree = new_t

  def error_handler(self, socketError):
    if socketError == QLocalSocket.LocalSocketError.PeerClosedError:
      app.exit()

if __name__ == "__main__":
  app = QApplication(sys.argv)
  window = MainWindow()
  app.setStyleSheet('QGraphicsView{border: 0px;}') # remove white outline around application
  window.show()
  sys.exit(app.exec())
