B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.5
@EndOfDesignText@
' Non-modal "This Document" panel (same floating style as FindBar/SetupBar): the active document's
' encoding and line endings, applied on its next save. Shown from View > This Document. Changes are
' pushed to Main.SetEncoding / Main.SetEol; while it's open Main keeps it on the active tab via
' RefreshPerDoc.
Sub Class_Globals
	Private pnl As Pane
	Private cmbEnc As ComboBox
	Private cmbEol As ComboBox
	Private chkReadOnly As CheckBox
	Private btnClose As Button
	Private mLoading As Boolean = False     ' suppresses control events while we populate the fields
	Private Const LBL As String = "-fx-font-family: 'Segoe UI'; -fx-font-size: 12; -fx-text-fill: -fx-text-base-color;"
	Private Const HDR As String = "-fx-font-family: 'Segoe UI'; -fx-font-size: 12; -fx-font-weight: bold; -fx-text-fill: -fx-text-base-color;"
	Private Const W As Int = 300
	Private Const H As Int = 132
End Sub

Public Sub Initialize
	pnl.Initialize("pnl")
	pnl.Style = "-fx-background-color: -fx-background; -fx-border-color: -fx-box-border; -fx-border-width: 1; -fx-effect: dropshadow(gaussian, rgba(0,0,0,0.3), 8, 0, 0, 2);"
	pnl.PrefWidth = W
	pnl.PrefHeight = H

	btnClose.Initialize("btnClose")
	btnClose.Text = "X"
	pnl.AddNode(btnClose, W - 32, 6, 24, 24)

	AddLabel(HDR, "This Document", 8, 6, 200)

	AddLabel(LBL, "Encoding:", 8, 38, 60)
	cmbEnc.Initialize("cmbEnc")
	For Each nm As String In Main.EncodingNames
		cmbEnc.Items.Add(nm)
	Next
	pnl.AddNode(cmbEnc, 72, 36, 130, 26)

	AddLabel(LBL, "Line endings:", 8, 70, 76)
	cmbEol.Initialize("cmbEol")
	cmbEol.Items.Add("CRLF (Windows)")    ' index 0 = CRLF
	cmbEol.Items.Add("LF (Unix)")         ' index 1 = LF
	pnl.AddNode(cmbEol, 88, 68, 130, 26)

	chkReadOnly.Initialize("chkReadOnly")
	chkReadOnly.Text = "Read only"
	chkReadOnly.Style = LBL
	pnl.AddNode(chkReadOnly, 8, 100, 200, 24)

	pnl.Visible = False
End Sub

Private Sub AddLabel (style As String, text As String, x As Int, y As Int, wd As Int)
	Dim lb As Label
	lb.Initialize("")
	lb.Text = text
	lb.Style = style
	pnl.AddNode(lb, x, y, wd, 22)
End Sub

Public Sub AsPanel As Pane
	Return pnl
End Sub

Public Sub IsVisible As Boolean
	Return pnl.Visible
End Sub

' Opens the panel populated with the active document's encoding/EOL/read-only.
Public Sub Show (enc As String, eol As String, readonly As Boolean)
	Populate(enc, eol, readonly)
	pnl.Visible = True
	cmbEnc.RequestFocus
End Sub

' Updates the controls for the now-active tab (called by Main on tab switch when the panel is open).
Public Sub RefreshPerDoc (enc As String, eol As String, readonly As Boolean)
	Populate(enc, eol, readonly)
End Sub

Private Sub Populate (enc As String, eol As String, readonly As Boolean)
	mLoading = True
	Dim i As Int = cmbEnc.Items.IndexOf(enc)
	If i >= 0 Then cmbEnc.SelectedIndex = i
	cmbEol.SelectedIndex = IIf(eol = "LF",1,0)
	chkReadOnly.Checked = readonly
	mLoading = False
End Sub

Public Sub Hide
	pnl.Visible = False
End Sub

Private Sub cmbEnc_SelectedIndexChanged (Index As Int, Value As String)
	If mLoading Then Return
	Main.SetEncoding(Value)
End Sub

Private Sub cmbEol_SelectedIndexChanged (Index As Int, Value As String)
	If mLoading Then Return
	If Index = 1 Then
		Main.SetEol("LF")
	Else
		Main.SetEol("CRLF")
	End If
End Sub

Private Sub chkReadOnly_CheckedChange (Checked As Boolean)
	If mLoading Then Return
	Main.SetReadOnly(Checked)
End Sub

Private Sub btnClose_Click
	Hide
End Sub
