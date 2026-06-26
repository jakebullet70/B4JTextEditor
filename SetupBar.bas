B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.5
@EndOfDesignText@
' Non-modal Setup panel (same floating style as FindBar): the global editor settings - theme, font
' (family+size), tab size, soft/hard tabs, line numbers, word wrap, highlight line, auto indent, and
' the defaults (encoding + line endings) for new documents. (The active document's encoding/EOL live
' in the separate ThisDocBar panel.) Changes are pushed straight to Main, which applies/persists them.
Sub Class_Globals
	Private pnl As Pane
	Private cmbTheme As ComboBox
	Private cmbFont As ComboBox
	Private txtSize As TextField
	Private txtTab As TextField
	Private chkSoftTabs As CheckBox
	Private chkLineNo As CheckBox
	Private chkWrap As CheckBox
	Private chkHiLine As CheckBox
	Private chkAutoIndent As CheckBox
	Private cmbDefEnc As ComboBox
	Private cmbDefEol As ComboBox
	Private btnClose As Button
	Private mLoading As Boolean = False     ' suppresses control events while Show populates the fields
	Private Const LBL As String = "-fx-font-family: 'Segoe UI'; -fx-font-size: 12; -fx-text-fill: -fx-text-base-color;"
	Private Const HDR As String = "-fx-font-family: 'Segoe UI'; -fx-font-size: 12; -fx-font-weight: bold; -fx-text-fill: -fx-text-base-color;"
	Private Const W As Int = 340
	Private Const H As Int = 228
End Sub

Public Sub Initialize
	pnl.Initialize("pnl")
	pnl.Style = "-fx-background-color: -fx-background; -fx-border-color: -fx-box-border; -fx-border-width: 1; -fx-effect: dropshadow(gaussian, rgba(0,0,0,0.3), 8, 0, 0, 2);"
	pnl.PrefWidth = W
	pnl.PrefHeight = H

	btnClose.Initialize("btnClose")
	btnClose.Text = "X"
	pnl.AddNode(btnClose, W - 32, 6, 24, 24)

	' ---- Global Settings ----
	AddHeader("Global Settings", 6)
	AddLabel("Theme:", 8, 34, 46)
	cmbTheme.Initialize("cmbTheme")
	cmbTheme.Items.Add("Light")    ' index 0
	cmbTheme.Items.Add("Dark")     ' index 1
	pnl.AddNode(cmbTheme, 56, 32, 120, 26)

	AddLabel("Font:", 8, 66, 36)
	cmbFont.Initialize("cmbFont")
	PopulateFonts
	pnl.AddNode(cmbFont, 48, 64, 150, 26)
	AddLabel("Size:", 204, 66, 34)
	txtSize.Initialize("txtSize")
	pnl.AddNode(txtSize, 240, 64, 46, 26)

	AddLabel("Tab size:", 8, 98, 60)
	txtTab.Initialize("txtTab")
	pnl.AddNode(txtTab, 70, 96, 46, 26)
	chkSoftTabs.Initialize("chkSoftTabs")
	chkSoftTabs.Text = "Insert spaces"
	chkSoftTabs.Style = LBL
	pnl.AddNode(chkSoftTabs, 124, 96, 150, 26)

	chkLineNo.Initialize("chkLineNo")
	chkLineNo.Text = "Show line numbers"
	chkLineNo.Style = LBL
	pnl.AddNode(chkLineNo, 8, 128, 150, 26)
	chkWrap.Initialize("chkWrap")
	chkWrap.Text = "Word wrap"
	chkWrap.Style = LBL
	pnl.AddNode(chkWrap, 170, 128, 120, 26)

	chkHiLine.Initialize("chkHiLine")
	chkHiLine.Text = "Highlight line"
	chkHiLine.Style = LBL
	pnl.AddNode(chkHiLine, 8, 160, 150, 26)
	chkAutoIndent.Initialize("chkAutoIndent")
	chkAutoIndent.Text = "Auto indent"
	chkAutoIndent.Style = LBL
	pnl.AddNode(chkAutoIndent, 170, 160, 120, 26)

	AddLabel("Default enc:", 8, 194, 72)
	cmbDefEnc.Initialize("cmbDefEnc")
	FillEncodings(cmbDefEnc)
	pnl.AddNode(cmbDefEnc, 82, 192, 110, 26)
	AddLabel("EOL:", 198, 194, 32)
	cmbDefEol.Initialize("cmbDefEol")
	FillEols(cmbDefEol)
	pnl.AddNode(cmbDefEol, 232, 192, 100, 26)

	pnl.Visible = False
	' Esc closes the panel (TextField has no KeyPressed event in the wrapper).
	Dim jo As JavaObject = Me
	jo.RunMethod("attachEsc", Array(txtTab))
	jo.RunMethod("attachEsc", Array(txtSize))
End Sub

Private Sub AddHeader (text As String, y As Int)
	Dim lb As Label
	lb.Initialize("")
	lb.Text = text
	lb.Style = HDR
	pnl.AddNode(lb, 8, y, 200, 20)
End Sub

Private Sub AddLabel (text As String, x As Int, y As Int, wd As Int)
	Dim lb As Label
	lb.Initialize("")
	lb.Text = text
	lb.Style = LBL
	pnl.AddNode(lb, x, y, wd, 24)
End Sub

Private Sub FillEncodings (cmb As ComboBox)
	For Each nm As String In Main.EncodingNames
		cmb.Items.Add(nm)
	Next
End Sub

Private Sub FillEols (cmb As ComboBox)
	cmb.Items.Add("CRLF (Windows)")    ' index 0 = CRLF
	cmb.Items.Add("LF (Unix)")         ' index 1 = LF
End Sub

' Fills the font combo with the installed JavaFX font families.
Private Sub PopulateFonts
	Dim fontStatic As JavaObject
	fontStatic.InitializeStatic("javafx.scene.text.Font")
	Dim fams As List = fontStatic.RunMethod("getFamilies", Null)
	For Each fam As String In fams
		cmbFont.Items.Add(fam)
	Next
End Sub

Public Sub AsPanel As Pane
	Return pnl
End Sub

' Opens the panel populated with the current settings (passed as a Map by Main).
Public Sub Show (s As Map)
	mLoading = True
	SelectByValue(cmbTheme, s.Get("theme"))
	SelectFont(s.Get("fontfamily"))
	txtSize.Text = s.Get("fontsize")
	txtTab.Text = s.Get("tabsize")
	chkSoftTabs.Checked = s.Get("softtabs")
	chkLineNo.Checked = s.Get("linenumbers")
	chkWrap.Checked = s.Get("wordwrap")
	chkHiLine.Checked = s.Get("highlightline")
	chkAutoIndent.Checked = s.Get("autoindent")
	SelectByValue(cmbDefEnc, s.Get("defenc"))
	SelectEol(cmbDefEol, s.Get("defeol"))
	mLoading = False
	pnl.Visible = True
	txtTab.RequestFocus
End Sub

Private Sub SelectByValue (cmb As ComboBox, value As String)
	Dim i As Int = cmb.Items.IndexOf(value)
	If i >= 0 Then cmb.SelectedIndex = i
End Sub

Private Sub SelectEol (cmb As ComboBox, eol As String)
	If eol = "LF" Then cmb.SelectedIndex = 1 Else cmb.SelectedIndex = 0
End Sub

Private Sub SelectFont (family As String)
	Dim i As Int = cmbFont.Items.IndexOf(family)
	If i < 0 And family <> "" Then          ' family not installed - show it anyway, at the top
		cmbFont.Items.InsertAt(0, family)
		i = 0
	End If
	If i >= 0 Then cmbFont.SelectedIndex = i
End Sub

Public Sub Hide
	pnl.Visible = False
End Sub

#Region Control events
Private Sub cmbTheme_SelectedIndexChanged (Index As Int, Value As String)
	If mLoading Then Return
	Main.SetTheme(Value)
End Sub

Private Sub cmbFont_SelectedIndexChanged (Index As Int, Value As String)
	If mLoading Then Return
	Main.SetFontFamily(Value)
End Sub

Private Sub txtSize_TextChanged (Old As String, New As String)
	If mLoading Then Return
	If IsNumber(New) = False Then Return
	Dim n As Int = New
	If n < 6 Then n = 6
	If n > 72 Then n = 72
	Main.SetFontSize(n)
End Sub

Private Sub txtSize_Action
	Hide
End Sub

' Live-applies a valid tab size (clamped 1..16) as the user types.
Private Sub txtTab_TextChanged (Old As String, New As String)
	If mLoading Then Return
	If IsNumber(New) = False Then Return
	Dim n As Int = New
	If n < 1 Then n = 1
	If n > 16 Then n = 16
	Main.SetTabSize(n)
End Sub

Private Sub txtTab_Action
	Hide
End Sub

Private Sub chkSoftTabs_CheckedChange (Checked As Boolean)
	If mLoading Then Return
	Main.SetSoftTabs(Checked)
End Sub

Private Sub chkLineNo_CheckedChange (Checked As Boolean)
	If mLoading Then Return
	Main.SetLineNumbers(Checked)
End Sub

Private Sub chkWrap_CheckedChange (Checked As Boolean)
	If mLoading Then Return
	Main.SetWordWrap(Checked)
End Sub

Private Sub chkHiLine_CheckedChange (Checked As Boolean)
	If mLoading Then Return
	Main.SetHighlightLine(Checked)
End Sub

Private Sub chkAutoIndent_CheckedChange (Checked As Boolean)
	If mLoading Then Return
	Main.SetAutoIndent(Checked)
End Sub

Private Sub cmbDefEnc_SelectedIndexChanged (Index As Int, Value As String)
	If mLoading Then Return
	Main.SetDefaultEncoding(Value)
End Sub

Private Sub cmbDefEol_SelectedIndexChanged (Index As Int, Value As String)
	If mLoading Then Return
	Main.SetDefaultEol(EolFor(Index))
End Sub

Private Sub EolFor (Index As Int) As String
	If Index = 1 Then Return "LF"
	Return "CRLF"
End Sub

Private Sub btnClose_Click
	Hide
End Sub

' Raised from inline Java when Esc is pressed in a field.
Private Sub onescape 'ignore
	Hide
End Sub
#End Region

#If JAVA
public void attachEsc(javafx.scene.control.TextField tf) {
    tf.addEventFilter(javafx.scene.input.KeyEvent.KEY_PRESSED, ev -> {
        if (ev.getCode() == javafx.scene.input.KeyCode.ESCAPE) {
            ba.raiseEventFromUI(this, "onescape", (Object[]) null);
        }
    });
}
#End If
