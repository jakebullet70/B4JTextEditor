B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.31
@EndOfDesignText@
' CodeEditor - a thin, swappable wrapper around the editor surface.
' Backing control: RichTextFX CodeArea (line-number gutter, virtualized scrolling, future syntax
' highlighting), driven through JavaObject. The CodeArea is wrapped in a flowless VirtualizedScrollPane
' so it gets scrollbars; that scroll pane is the node added to the UI (AsNode).
' The small API below lets the surface be swapped without touching Main. See plan Section 2.
Sub Class_Globals
	Private mArea As JavaObject         ' org.fxmisc.richtext.CodeArea
	Private mNode As JavaObject         ' org.fxmisc.flowless.VirtualizedScrollPane wrapping mArea
End Sub

Public Sub Initialize
	mArea.InitializeNewInstance("org.fxmisc.richtext.CodeArea", Null)
	' Line-number gutter.
	Dim lnf As JavaObject
	lnf.InitializeStatic("org.fxmisc.richtext.LineNumberFactory")
	Dim factory As Object = lnf.RunMethod("get", Array(mArea))
	mArea.RunMethod("setParagraphGraphicFactory", Array(factory))
	mArea.RunMethod("setStyle", Array("-fx-font-family: 'Consolas','Courier New','monospace'; -fx-font-size: 14;"))
	mArea.RunMethod("setWrapText", Array(False))
	mNode.InitializeNewInstance("org.fxmisc.flowless.VirtualizedScrollPane", Array(mArea))
	' Tab inserts spaces (soft tabs); count is configurable via SetTabSize.
	Dim jo As JavaObject = Me
	jo.RunMethod("installTabHandler", Array(mArea))
End Sub

' Number of spaces inserted when Tab is pressed; also the render width of literal tabs from files.
Public Sub SetTabSize (n As Int)
	Dim jo As JavaObject = Me
	jo.RunMethod("setTabSize", Array(mArea, n))
End Sub

' Shows/hides the line-number gutter.
Public Sub SetLineNumbers (b As Boolean)
	Dim jo As JavaObject = Me
	jo.RunMethod("setLineNumbers", Array(mArea, b))
End Sub

' Sets the editor font (family falls back through Consolas -> generic monospace). Background/text
' colors are left to the theme stylesheet, so no -fx-background-color here.
Public Sub SetFont (family As String, size As Int)
	mArea.RunMethod("setStyle", Array($"-fx-font-family: '${family}','Consolas','monospace'; -fx-font-size: ${size};"$))
End Sub

' True = Tab inserts spaces (soft tabs); False = Tab inserts a real tab character (hard tabs).
Public Sub SetSoftTabs (b As Boolean)
	Dim jo As JavaObject = Me
	jo.RunMethod("setSoftTabs", Array(b))
End Sub

' True = Enter copies the current line's leading whitespace to the new line.
Public Sub SetAutoIndent (b As Boolean)
	Dim jo As JavaObject = Me
	jo.RunMethod("setAutoIndent", Array(b))
End Sub

' Enables/disables the current-line background highlight.
Public Sub SetHighlightLine (b As Boolean)
	Dim jo As JavaObject = Me
	jo.RunMethod("setHighlightLine", Array(mArea, b))
End Sub

' Moves the current-line highlight to the caret's line (called from Main's caret poll).
Public Sub RefreshCurrentLine
	Dim jo As JavaObject = Me
	jo.RunMethod("refreshHl", Array(mArea))
End Sub


' The node to add to a pane (the scroll pane that hosts the CodeArea).
Public Sub AsNode As JavaObject
	Return mNode
End Sub

Public Sub setText (t As String)
	Dim len As Int = mArea.RunMethod("getLength", Null)
	mArea.RunMethod("replaceText", Array(0, len, t))
	' Don't let a programmatic load be undoable back to the previous document.
	Dim um As JavaObject = mArea.RunMethodJO("getUndoManager", Null)
	um.RunMethod("forgetHistory", Null)
End Sub

Public Sub getText As String
	Return mArea.RunMethod("getText", Null)
End Sub

Public Sub TextLength As Int
	Return mArea.RunMethod("getLength", Null)
End Sub

Public Sub Undo
	mArea.RunMethod("undo", Null)
End Sub

Public Sub Redo
	mArea.RunMethod("redo", Null)
End Sub

Public Sub Cut
	mArea.RunMethod("cut", Null)
End Sub

Public Sub Copy
	mArea.RunMethod("copy", Null)
End Sub

Public Sub Paste
	mArea.RunMethod("paste", Null)
End Sub

Public Sub SelectAll
	mArea.RunMethod("selectAll", Null)
End Sub

' Caret index (0-based) within the whole text.
Public Sub GetCaret As Int
	Return mArea.RunMethod("getCaretPosition", Null)
End Sub

' 1-based line of the caret.
Public Sub GetCaretLine As Int
	Return mArea.RunMethod("getCurrentParagraph", Null) + 1
End Sub

' 1-based column of the caret within its line.
Public Sub GetCaretColumn As Int
	Return mArea.RunMethod("getCaretColumn", Null) + 1
End Sub

' Selects [startIndex, endIndex) and scrolls the caret into view.
Public Sub SelectRange (startIndex As Int, endIndex As Int)
	mArea.RunMethod("selectRange", Array(startIndex, endIndex))
	mArea.RunMethod("requestFollowCaret", Null)
End Sub

Public Sub SetWrap (b As Boolean)
	mArea.RunMethod("setWrapText", Array(b))
End Sub

Public Sub RequestFocus
	mArea.RunMethod("requestFocus", Null)
End Sub

' Read-only when False (the CodeArea rejects edits but stays selectable/scrollable).
Public Sub SetEditable (b As Boolean)
	mArea.RunMethod("setEditable", Array(b))
End Sub

Public Sub IsEditable As Boolean
	Return mArea.RunMethod("isEditable", Null)
End Sub

Public Sub GetSelectedText As String
	Return mArea.RunMethod("getSelectedText", Null)
End Sub

Public Sub ReplaceSelection (t As String)
	mArea.RunMethod("replaceSelection", Array(t))
End Sub

' Replaces the entire content but keeps undo history (unlike setText, which forgets it).
Public Sub ReplaceContent (t As String)
	Dim len As Int = mArea.RunMethod("getLength", Null)
	mArea.RunMethod("replaceText", Array(0, len, t))
End Sub

' Moves the caret to the start of a 0-based line and scrolls it into view.
Public Sub GotoLine (lineIndexZeroBased As Int)
	mArea.RunMethod("moveTo", Array(lineIndexZeroBased, 0))
	mArea.RunMethod("requestFollowCaret", Null)
End Sub

' Puts the caret at the start and scrolls the first line to the top (used after loading a file -
' replaceText otherwise leaves the view scrolled to the bottom).
Public Sub ScrollToTop
	Dim jo As JavaObject = Me
	jo.RunMethod("scrollToTop", Array(mArea))
End Sub

' --- Syntax highlighting bridge ---
' Adds a CSS stylesheet (file URI) that defines the token style classes.
Public Sub SetStylesheet (uri As String)
	Dim jo As JavaObject = Me
	jo.RunMethod("nativeAddStylesheet", Array(mArea, uri))
End Sub

' Applies style spans computed from a combined named-group regex. groupNames[i] -> styleClasses[i].
Public Sub ApplyStyleSpans (pattern As String, groupNames() As String, styleClasses() As String)
	Dim jo As JavaObject = Me
	jo.RunMethod("nativeHighlight", Array(mArea, pattern, groupNames, styleClasses))
End Sub

Public Sub ClearStyles
	Dim jo As JavaObject = Me
	jo.RunMethod("nativeClear", Array(mArea))
End Sub

#If JAVA
private int _tabSize = 3;
private boolean _softTabs = true;
private boolean _autoIndent = true;
private boolean _hlEnabled = false;
private int _hlLast = -1;

public void setSoftTabs(boolean b) {
    _softTabs = b;
}

public void setAutoIndent(boolean b) {
    _autoIndent = b;
}

// Current-line highlight: applies the "current-line" paragraph style to the caret's line and
// removes it from the previous one. Driven by Main's caretTimer (refreshHl) - no extra listener.
public void setHighlightLine(org.fxmisc.richtext.CodeArea area, boolean on) {
    _hlEnabled = on;
    if (on) refreshHl(area); else clearHl(area);
}

private void clearHl(org.fxmisc.richtext.CodeArea area) {
    if (_hlLast >= 0 && _hlLast < area.getParagraphs().size()) {
        area.setParagraphStyle(_hlLast, java.util.Collections.<String>emptyList());
    }
    _hlLast = -1;
}

public void refreshHl(org.fxmisc.richtext.CodeArea area) {
    if (!_hlEnabled) return;
    int cur = area.getCurrentParagraph();
    if (cur == _hlLast) return;
    if (_hlLast >= 0 && _hlLast < area.getParagraphs().size()) {
        area.setParagraphStyle(_hlLast, java.util.Collections.<String>emptyList());
    }
    if (cur >= 0 && cur < area.getParagraphs().size()) {
        area.setParagraphStyle(cur, java.util.Collections.singletonList("current-line"));
    }
    _hlLast = cur;
}

public void setTabSize(org.fxmisc.richtext.CodeArea area, int n) {
    _tabSize = n;
    applyTabSizeToVisible(area);   // update render width of any literal tabs already on screen
}

// Sets JavaFX tabSize on every realized paragraph TextFlow so literal '\t' chars (from opened
// files) render at the chosen width. RichTextFX recreates these nodes on scroll, so this is
// reapplied via the listeners in installTabHandler.
private void applyTabSizeToVisible(org.fxmisc.richtext.CodeArea area) {
    for (javafx.scene.Node node : area.lookupAll(".paragraph-text")) {
        if (node instanceof javafx.scene.text.TextFlow) {
            ((javafx.scene.text.TextFlow) node).setTabSize(_tabSize);
        }
    }
}

// Intercept Tab: insert spaces (soft tabs) or a real tab char (hard tabs). We always handle the
// insertion ourselves so the count/character is under our control.
public void installTabHandler(final org.fxmisc.richtext.CodeArea area) {
    area.addEventFilter(javafx.scene.input.KeyEvent.KEY_PRESSED, ev -> {
        if (ev.isControlDown() || ev.isAltDown()) return;   // leave shortcuts alone
        javafx.scene.input.KeyCode code = ev.getCode();
        if (code == javafx.scene.input.KeyCode.TAB && !ev.isShiftDown()) {
            ev.consume();
            if (_softTabs) {
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < _tabSize; i++) sb.append(' ');
                area.replaceSelection(sb.toString());
            } else {
                area.replaceSelection("\t");
            }
        } else if (code == javafx.scene.input.KeyCode.ENTER && _autoIndent) {
            ev.consume();
            String line = area.getText(area.getCurrentParagraph());   // current line's text
            int i = 0;
            while (i < line.length() && (line.charAt(i) == ' ' || line.charAt(i) == '\t')) i++;
            area.replaceSelection("\n" + line.substring(0, i));        // newline + same leading indent
        }
    });
    // Tab fires a separate KEY_TYPED '\t'; Enter fires '\r'/'\n'. When we handle those keys above
    // we must consume the typed char too, or a literal char slips in on top.
    area.addEventFilter(javafx.scene.input.KeyEvent.KEY_TYPED, ev -> {
        String ch = ev.getCharacter();
        if (ch == null) return;
        if (ch.equals("\t")) ev.consume();
        else if (_autoIndent && (ch.equals("\r") || ch.equals("\n"))) ev.consume();
    });
    // Reapply the literal-tab render width whenever paragraph nodes are (re)created — on scroll or
    // resize (visible-paragraph set changes) and on edits (plainTextChanges). Deferred so the scan
    // runs after the nodes are laid out.
    area.getVisibleParagraphs().addListener((javafx.beans.InvalidationListener) obs ->
        javafx.application.Platform.runLater(() -> applyTabSizeToVisible(area)));
    area.plainTextChanges().subscribe(c ->
        javafx.application.Platform.runLater(() -> applyTabSizeToVisible(area)));
}

public void setLineNumbers(org.fxmisc.richtext.CodeArea area, boolean on) {
    if (on) {
        area.setParagraphGraphicFactory(org.fxmisc.richtext.LineNumberFactory.get(area));
    } else {
        area.setParagraphGraphicFactory(null);
    }
}

public void scrollToTop(final org.fxmisc.richtext.CodeArea area) {
    area.moveTo(0);
    javafx.application.Platform.runLater(() -> {
        area.showParagraphAtTop(0);
        area.scrollYToPixel(0);
    });
}

public void nativeAddStylesheet(org.fxmisc.richtext.CodeArea area, String uri) {
    area.getStylesheets().clear();   // keep exactly one theme stylesheet so theme switches replace it
    area.getStylesheets().add(uri);
}

public void nativeClear(org.fxmisc.richtext.CodeArea area) {
    int len = area.getLength();
    if (len > 0) area.clearStyle(0, len);
}

public void nativeHighlight(org.fxmisc.richtext.CodeArea area, String regex, String[] names, String[] classes) {
    String text = area.getText();
    if (text.isEmpty()) return;
    java.util.regex.Matcher m = java.util.regex.Pattern.compile(regex).matcher(text);
    org.fxmisc.richtext.model.StyleSpansBuilder<java.util.Collection<String>> sb =
        new org.fxmisc.richtext.model.StyleSpansBuilder<java.util.Collection<String>>();
    int last = 0;
    while (m.find()) {
        String cls = "plain";
        for (int i = 0; i < names.length; i++) {
            if (m.group(names[i]) != null) { cls = classes[i]; break; }
        }
        if (m.start() > last) sb.add(java.util.Collections.<String>emptyList(), m.start() - last);
        if (m.end() > m.start()) sb.add(java.util.Collections.singleton(cls), m.end() - m.start());
        last = m.end();
    }
    if (text.length() > last) sb.add(java.util.Collections.<String>emptyList(), text.length() - last);
    area.setStyleSpans(0, sb.create());
}
#End If
