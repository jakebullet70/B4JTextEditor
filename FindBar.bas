B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.5
@EndOfDesignText@
' Non-modal, VS Code-style find/replace widget. A floating panel pinned to the top-right of the
' editor. Owns its own search state and logic over the CodeEditor; Main just shows/hides it.
' Options (an always-visible row): Match case, Whole word, Regex, and All tabs (cross-document).
' Matching uses B4X Regex so matches can be variable length (regex) - each match carries (start,len).
Sub Class_Globals
	Private mEditor As CodeEditor
	Private mHighlighter As SyntaxHL
	Private pnl As Pane
	Private txtFind As TextField
	Private txtReplace As TextField
	Private lblCount As Label
	Private chkCase, chkWord, chkRegex, chkAll As CheckBox
	Private btnPrev, btnNext, btnReplace, btnReplaceAll, btnClose As Button
	Private mRepCount As Int                   ' out-params of BuildReplacement (B4X has no tuples)
	Private mRepError As Boolean
	Private Const W As Int = 500
	Private Const H_FIND As Int = 74          ' find row + options row
	Private Const H_REPLACE As Int = 106      ' + replace row
End Sub

Public Sub Initialize (highlighter As SyntaxHL)
	mHighlighter = highlighter
	pnl.Initialize("pnl")
	pnl.Style = "-fx-background-color: -fx-background; -fx-border-color: -fx-box-border; -fx-border-width: 1; -fx-effect: dropshadow(gaussian, rgba(0,0,0,0.3), 8, 0, 0, 2);"
	pnl.PrefWidth = W
	pnl.PrefHeight = H_FIND

	' Row 1: find field + nav + count + close.
	txtFind.Initialize("txtFind")
	txtFind.PromptText = "Find"
	pnl.AddNode(txtFind, 8, 9, 260, 26)
	btnPrev.Initialize("btnPrev")
	btnPrev.Text = "Prev"
	pnl.AddNode(btnPrev, 272, 9, 42, 26)
	btnNext.Initialize("btnNext")
	btnNext.Text = "Next"
	pnl.AddNode(btnNext, 318, 9, 42, 26)
	lblCount.Initialize("")
	lblCount.Style = "-fx-font-family: 'Segoe UI'; -fx-font-size: 11; -fx-text-fill: -fx-text-base-color;"
	pnl.AddNode(lblCount, 366, 9, 100, 26)
	btnClose.Initialize("btnClose")
	btnClose.Text = "X"
	pnl.AddNode(btnClose, W - 30, 9, 26, 26)

	' Row 2: search options (always visible).
	chkCase.Initialize("chkCase")
	chkCase.Text = "Match case"
	pnl.AddNode(chkCase, 8, 43, 90, 24)
	chkWord.Initialize("chkWord")
	chkWord.Text = "Whole word"
	pnl.AddNode(chkWord, 104, 43, 100, 24)
	chkRegex.Initialize("chkRegex")
	chkRegex.Text = "Regex"
	pnl.AddNode(chkRegex, 210, 43, 78, 24)
	chkAll.Initialize("chkAll")
	chkAll.Text = "All tabs"
	pnl.AddNode(chkAll, 296, 43, 90, 24)

	' Row 3: replace field + actions (shown only in replace mode).
	txtReplace.Initialize("txtReplace")
	txtReplace.PromptText = "Replace"
	pnl.AddNode(txtReplace, 8, 73, 260, 26)
	btnReplace.Initialize("btnReplace")
	btnReplace.Text = "Replace"
	pnl.AddNode(btnReplace, 272, 73, 90, 26)
	btnReplaceAll.Initialize("btnReplaceAll")
	btnReplaceAll.Text = "Replace All"
	pnl.AddNode(btnReplaceAll, 368, 73, 110, 26)

	pnl.Visible = False
	' Esc closes the bar (TextField has no KeyPressed event in the wrapper).
	Dim jo As JavaObject = Me
	jo.RunMethod("attachEsc", Array(txtFind))
	jo.RunMethod("attachEsc", Array(txtReplace))
End Sub

Public Sub AsPanel As Pane
	Return pnl
End Sub

' Re-points the bar at the active document's editor (multi-document support).
Public Sub SetEditor (editor As CodeEditor)
	mEditor = editor
End Sub

Public Sub ShowFind
	SetReplaceRow(False)
	pnl.PrefHeight = H_FIND
	pnl.Visible = True
	PrefillFromSelection
	txtFind.RequestFocus
End Sub

Public Sub ShowReplace
	SetReplaceRow(True)
	pnl.PrefHeight = H_REPLACE
	pnl.Visible = True
	PrefillFromSelection
	txtFind.RequestFocus
End Sub

' Used by F3 / Find Next menu: open the bar if hidden, else jump to the next match.
Public Sub FindNextOrShow
	If pnl.Visible = False Or txtFind.Text = "" Then
		ShowFind
	Else
		FindNext
	End If
End Sub

Public Sub Hide
	pnl.Visible = False
	mEditor.RequestFocus
End Sub

Private Sub SetReplaceRow (v As Boolean)
	txtReplace.Visible = v
	btnReplace.Visible = v
	btnReplaceAll.Visible = v
End Sub

Private Sub PrefillFromSelection
	Dim s As String = mEditor.GetSelectedText
	If s <> "" And s.Contains(Chr(10)) = False Then txtFind.Text = s
End Sub

#Region Find
Private Sub txtFind_Action
	FindNext
End Sub

Private Sub btnNext_Click
	FindNext
End Sub

Private Sub btnPrev_Click
	FindPrev
End Sub

' Option toggles + typing: refresh the count for the current scope (matching reads the checkboxes
' live, so there's nothing to cache).
Private Sub chkCase_CheckedChange (Checked As Boolean)
	RefreshCount
End Sub

Private Sub chkWord_CheckedChange (Checked As Boolean)
	RefreshCount
End Sub

Private Sub chkRegex_CheckedChange (Checked As Boolean)
	RefreshCount
End Sub

Private Sub chkAll_CheckedChange (Checked As Boolean)
	RefreshCount
End Sub

Private Sub txtFind_TextChanged (Old As String, New As String)
	RefreshCount
End Sub

' Case-insensitive unless Match case is ticked.
Private Sub CaseOpts As Int
	If chkCase.Checked Then Return 0
	Return Regex.CASE_INSENSITIVE
End Sub

' Shows "<n> matches" (or No results / Bad regex) for the current scope without moving the caret.
Private Sub RefreshCount
	If txtFind.Text = "" Then
		lblCount.Text = ""
		Return
	End If
	Dim total As Int = 0
	If chkAll.Checked Then
		For di = 0 To Main.DocCount - 1
			Dim mm As List = MatchesIn(Main.DocEditorAt(di), txtFind.Text)
			If mm.IsInitialized = False Then
				lblCount.Text = "Bad regex"
				Return
			End If
			total = total + mm.Size
		Next
	Else
		Dim mm As List = MatchesIn(mEditor, txtFind.Text)
		If mm.IsInitialized = False Then
			lblCount.Text = "Bad regex"
			Return
		End If
		total = mm.Size
	End If
	If total = 0 Then
		lblCount.Text = "No results"
	Else
		lblCount.Text = total & " matches"
	End If
End Sub

Public Sub FindNext
	If chkAll.Checked Then FindNextAll Else FindNextOne
End Sub

Public Sub FindPrev
	If chkAll.Checked Then FindPrevAll Else FindPrevOne
End Sub

#Region Single document
Private Sub FindNextOne
	If txtFind.Text = "" Then Return
	Dim matches As List = MatchesIn(mEditor, txtFind.Text)
	If matches.IsInitialized = False Then
		lblCount.Text = "Bad regex"
		Return
	End If
	If matches.Size = 0 Then
		lblCount.Text = "No results"
		Return
	End If
	Dim caret As Int = mEditor.GetCaret
	Dim ti As Int = -1
	For i = 0 To matches.Size - 1
		Dim pr() As Int = matches.Get(i)
		If pr(0) >= caret Then
			ti = i
			Exit
		End If
	Next
	If ti = -1 Then ti = 0          ' wrap to first
	Dim pr() As Int = matches.Get(ti)
	SelectMatch(pr(0), pr(1), ti + 1, matches.Size)
End Sub

Private Sub FindPrevOne
	If txtFind.Text = "" Then Return
	Dim matches As List = MatchesIn(mEditor, txtFind.Text)
	If matches.IsInitialized = False Then
		lblCount.Text = "Bad regex"
		Return
	End If
	If matches.Size = 0 Then
		lblCount.Text = "No results"
		Return
	End If
	Dim selStart As Int = mEditor.GetCaret - SelLength
	If selStart < 0 Then selStart = 0
	Dim ti As Int = -1
	For i = matches.Size - 1 To 0 Step -1
		Dim pr() As Int = matches.Get(i)
		If pr(0) < selStart Then
			ti = i
			Exit
		End If
	Next
	If ti = -1 Then ti = matches.Size - 1     ' wrap to last
	Dim pr() As Int = matches.Get(ti)
	SelectMatch(pr(0), pr(1), ti + 1, matches.Size)
End Sub

Private Sub SelectMatch (idx As Int, len As Int, pos As Int, total As Int)
	mEditor.SelectRange(idx, idx + len)
	lblCount.Text = pos & " of " & total
End Sub
#End Region

#Region All documents
Private Sub FindNextAll
	If txtFind.Text = "" Then Return
	Dim nDocs As Int = Main.DocCount
	Dim active As Int = Main.ActiveDocIndex
	Dim curMatches As List = MatchesIn(mEditor, txtFind.Text)
	If curMatches.IsInitialized = False Then
		lblCount.Text = "Bad regex"
		Return
	End If
	Dim caret As Int = mEditor.GetCaret
	For i = 0 To curMatches.Size - 1
		Dim pr() As Int = curMatches.Get(i)
		If pr(0) >= caret Then
			SelectGlobal(active, pr(0), pr(1))
			Return
		End If
	Next
	For s = 1 To nDocs
		Dim di As Int = (active + s) Mod nDocs
		If di = active Then
			If curMatches.Size > 0 Then
				Dim pr0() As Int = curMatches.Get(0)
				SelectGlobal(active, pr0(0), pr0(1))
				Return
			End If
		Else
			Dim m As List = MatchesIn(Main.DocEditorAt(di), txtFind.Text)
			If m.IsInitialized And m.Size > 0 Then
				Dim mp() As Int = m.Get(0)
				SelectGlobal(di, mp(0), mp(1))
				Return
			End If
		End If
	Next
	lblCount.Text = "No results"
End Sub

Private Sub FindPrevAll
	If txtFind.Text = "" Then Return
	Dim nDocs As Int = Main.DocCount
	Dim active As Int = Main.ActiveDocIndex
	Dim curMatches As List = MatchesIn(mEditor, txtFind.Text)
	If curMatches.IsInitialized = False Then
		lblCount.Text = "Bad regex"
		Return
	End If
	Dim selStart As Int = mEditor.GetCaret - SelLength
	If selStart < 0 Then selStart = 0
	For i = curMatches.Size - 1 To 0 Step -1
		Dim pr() As Int = curMatches.Get(i)
		If pr(0) < selStart Then
			SelectGlobal(active, pr(0), pr(1))
			Return
		End If
	Next
	For s = 1 To nDocs
		Dim di As Int = (((active - s) Mod nDocs) + nDocs) Mod nDocs
		If di = active Then
			If curMatches.Size > 0 Then
				Dim prL() As Int = curMatches.Get(curMatches.Size - 1)
				SelectGlobal(active, prL(0), prL(1))
				Return
			End If
		Else
			Dim m As List = MatchesIn(Main.DocEditorAt(di), txtFind.Text)
			If m.IsInitialized And m.Size > 0 Then
				Dim mp() As Int = m.Get(m.Size - 1)
				SelectGlobal(di, mp(0), mp(1))
				Return
			End If
		End If
	Next
	lblCount.Text = "No results"
End Sub

Private Sub SelectGlobal (docIndex As Int, startIdx As Int, len As Int)
	If docIndex <> Main.ActiveDocIndex Then Main.GoToDoc(docIndex)   ' repoints mEditor via SetEditor
	mEditor.SelectRange(startIdx, startIdx + len)
	Dim total As Int = 0
	Dim pos As Int = 0
	For di = 0 To Main.DocCount - 1
		Dim m As List = MatchesIn(Main.DocEditorAt(di), txtFind.Text)
		If m.IsInitialized = False Then Continue
		If di < docIndex Then pos = pos + m.Size
		If di = docIndex Then
			For k = 0 To m.Size - 1
				Dim pr() As Int = m.Get(k)
				If pr(0) = startIdx Then
					pos = pos + k + 1
					Exit
				End If
			Next
		End If
		total = total + m.Size
	Next
	lblCount.Text = pos & " of " & total
	txtFind.RequestFocus            ' switching docs focuses the editor; keep typing in the find box
End Sub
#End Region

' Length of the current selection (used to step backwards over the just-selected match).
Private Sub SelLength As Int
	Return mEditor.GetSelectedText.Length
End Sub

' All matches of the term in a given editor, honouring the option toggles. Each item is an Int(2)
' {startIndex, length}. Returns an UNINITIALIZED list when the regex pattern is invalid.
Private Sub MatchesIn (ed As CodeEditor, term As String) As List
	Dim r As List
	Dim pat As String = BuildPattern(term)
	If pat = "" Then
		r.Initialize
		Return r
	End If
	Dim m As Matcher
	Try
		m = Regex.Matcher2(pat, CaseOpts, ed.Text)
	Catch
		Return r                    ' uninitialized = invalid pattern
	End Try
	r.Initialize
	Do While m.Find
		Dim pair(2) As Int
		pair(0) = m.GetStart(0)
		pair(1) = m.GetEnd(0) - m.GetStart(0)
		r.Add(pair)
	Loop
	Return r
End Sub

' The core pattern (regex as-typed, or the literal term escaped).
Private Sub CorePattern (term As String) As String
	If term = "" Then Return ""
	If chkRegex.Checked Then Return term
	Return QuoteRegex(term)
End Sub

' The full pattern: core, wrapped with word boundaries when Whole word is on.
Private Sub BuildPattern (term As String) As String
	Dim p As String = CorePattern(term)
	If p = "" Then Return ""
	If chkWord.Checked Then Return "\b(?:" & p & ")\b"
	Return p
End Sub

' Escapes regex metacharacters so a literal term is matched verbatim (java \Q..\E).
Private Sub QuoteRegex (s As String) As String
	Dim jo As JavaObject
	jo.InitializeStatic("java.util.regex.Pattern")
	Return jo.RunMethod("quote", Array(s))
End Sub
#End Region

#Region Replace
Private Sub btnReplace_Click
	If txtFind.Text = "" Then Return
	Dim sel As String = mEditor.GetSelectedText
	If sel.Length > 0 And SelectionIsMatch(sel) Then
		' Replace just the selected match; BuildReplacement substitutes $1.. groups in regex mode.
		Dim newSel As String = BuildReplacement(sel, txtFind.Text)
		If mRepError = False Then
			mEditor.ReplaceSelection(newSel)
			mHighlighter.Highlight(mEditor.Text)
		End If
	End If
	FindNext            ' advance (single- or all-docs per the toggle)
End Sub

' True if the current selection is exactly one match of the term (anchored core pattern).
Private Sub SelectionIsMatch (sel As String) As Boolean
	Dim core As String = CorePattern(txtFind.Text)
	If core = "" Then Return False
	Try
		Dim m As Matcher = Regex.Matcher2("^(?:" & core & ")$", CaseOpts, sel)
		Return m.Find
	Catch
		Return False
	End Try
End Sub

Private Sub btnReplaceAll_Click
	If chkAll.Checked Then ReplaceAllAll Else ReplaceAllOne
End Sub

Private Sub ReplaceAllOne
	If txtFind.Text = "" Then Return
	Dim newText As String = BuildReplacement(mEditor.Text, txtFind.Text)
	If mRepError Then
		lblCount.Text = "Bad regex"
		Return
	End If
	If mRepCount > 0 Then
		mEditor.ReplaceContent(newText)
		mHighlighter.Highlight(mEditor.Text)
	End If
	lblCount.Text = mRepCount & " replaced"
End Sub

Private Sub ReplaceAllAll
	If txtFind.Text = "" Then Return
	Dim totalCount As Int = 0
	For di = 0 To Main.DocCount - 1
		Dim ed As CodeEditor = Main.DocEditorAt(di)
		Dim newText As String = BuildReplacement(ed.Text, txtFind.Text)
		If mRepError Then
			lblCount.Text = "Bad regex"
			Return
		End If
		If mRepCount > 0 Then
			ed.ReplaceContent(newText)
			Main.NoteDocChanged(di)         ' flag modified + tab star (active re-highlights below)
			totalCount = totalCount + mRepCount
		End If
	Next
	mHighlighter.Highlight(mEditor.Text)    ' active doc; others re-highlight when switched to
	lblCount.Text = totalCount & " replaced"
End Sub

' Replaces every match of term in src with the replacement field, substituting $1.. group references
' in Regex mode (literal in non-regex mode, via Matcher.quoteReplacement). Returns the new string;
' sets mRepCount and mRepError (a bad pattern OR a bad group reference like $9 with fewer groups).
Private Sub BuildReplacement (src As String, term As String) As String
	mRepCount = 0
	mRepError = False
	Dim pat As String = BuildPattern(term)
	If pat = "" Then Return src
	Dim patClass As JavaObject
	patClass.InitializeStatic("java.util.regex.Pattern")
	Dim compiled As JavaObject
	Try
		compiled = patClass.RunMethodJO("compile", Array(pat, CaseOpts))
	Catch
		mRepError = True
		Return src
	End Try
	Dim repl As String = txtReplace.Text
	If chkRegex.Checked = False Then            ' literal: escape $ and \ so they aren't group syntax
		Dim mClass As JavaObject
		mClass.InitializeStatic("java.util.regex.Matcher")
		repl = mClass.RunMethod("quoteReplacement", Array(repl))
	End If
	Dim matcher As JavaObject = compiled.RunMethodJO("matcher", Array(src))
	Dim sb As JavaObject
	sb.InitializeNewInstance("java.lang.StringBuffer", Null)
	Try
		Do While matcher.RunMethod("find", Null)
			matcher.RunMethod("appendReplacement", Array(sb, repl))
			mRepCount = mRepCount + 1
		Loop
	Catch
		mRepError = True                       ' e.g. invalid group reference in the replacement
		Return src
	End Try
	matcher.RunMethod("appendTail", Array(sb))
	Return sb.RunMethod("toString", Null)
End Sub
#End Region

Private Sub btnClose_Click
	Hide
End Sub

' Raised from inline Java when Esc is pressed in a field.
Private Sub onescape 'ignore
	Hide
End Sub

#If JAVA
public void attachEsc(javafx.scene.control.TextField tf) {
    tf.addEventFilter(javafx.scene.input.KeyEvent.KEY_PRESSED, ev -> {
        if (ev.getCode() == javafx.scene.input.KeyCode.ESCAPE) {
            ba.raiseEventFromUI(this, "onescape", (Object[]) null);
        }
    });
}
#End If
