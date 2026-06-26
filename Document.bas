B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.5
@EndOfDesignText@
' One open document = one tab. Holds its own CodeEditor (so text, undo history and highlighting are
' preserved per tab) plus the per-document state. Main mirrors the active Document into its globals.
Sub Class_Globals
	Public editor As CodeEditor
	Public page As TabPage
	Public id As String = ""        ' unique tab id, used to find this doc when its X is clicked
	Public path As String = ""
	Public dir As String = ""
	Public modified As Boolean = False
	Public eol As String = "CRLF"
	Public encoding As String = "UTF-8"
	Public baseline As String = ""
	Public langName As String = "Plain"
	Public readonly As Boolean = False
	Public displayName As String = ""    ' custom tab title (e.g. the help doc); "" = use the file name
	Public lastHLText As String = Chr(0)
	Public lastCaret As Int = -1
	Public lastLen As Int = -1
End Sub

Public Sub Initialize (cssUri As String)
	editor.Initialize
	editor.SetStylesheet(cssUri)
End Sub

' Wires the tab's close (X) button to route through Main's save-prompt instead of closing natively.
Public Sub AttachClose
	Dim jo As JavaObject = Me
	jo.RunMethod("attachClose", Array(page))
End Sub

' Raised from inline Java when the user clicks the tab's X. Routed to Main for the save prompt.
Private Sub tabclose_event (tabId As String)
	Main.TabCloseRequest(tabId)
End Sub

#If JAVA
public void attachClose(final javafx.scene.control.Tab tab) {
	tab.setOnCloseRequest(ev -> {
		ev.consume();   // cancel native close; Main decides after a possible save prompt
		ba.raiseEventFromUI(this, "tabclose_event", new Object[]{ tab.getId() });
	});
}
#End If
