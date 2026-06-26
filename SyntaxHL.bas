B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.5
@EndOfDesignText@
' Syntax-highlighting engine. Owns the language registry and decides what/when to highlight;
' the actual StyleSpans are built by CodeEditor's inline-Java bridge. One regex-driven engine,
' many language configs (from SyntaxLanguages). Adding a language = add data, not code.
Sub Class_Globals
	Private mEditor As CodeEditor
	Private mLangs As List              ' processed language Maps (with regex/groupNames/styleClasses)
	Private mByExt As Map               ' extension -> language Map
	Private mCurrent As Map             ' current language, or an uninitialized Map for "Plain"
	' Fixed token categories, in precedence order (comments/strings first; types before keywords so a
	' word listed as both is coloured as a type).
	Private CATS() As String = Array As String("comment","string","char","annotation","number","type","keyword")
End Sub

Public Sub Initialize
	mLangs.Initialize
	mByExt.Initialize
	Dim raw As List = SyntaxLanguages.GetLanguages
	For Each lang As Map In raw
		BuildRegex(lang)
		mLangs.Add(lang)
		Dim exts As List = lang.Get("extensions")
		For Each e As String In exts
			mByExt.Put(e.ToLowerCase, lang)
		Next
	Next
	Dim none As Map        ' uninitialized = Plain (no highlighting)
	mCurrent = none
End Sub

' Re-points the highlighter at the active document's editor (multi-document support).
Public Sub SetEditor (editor As CodeEditor)
	mEditor = editor
End Sub

' Builds the combined named-group regex and parallel groupNames/styleClasses lists into the Map.
Private Sub BuildRegex (lang As Map)
	Dim parts As List
	parts.Initialize
	Dim grpNames As List
	grpNames.Initialize
	Dim styleCls As List
	styleCls.Initialize
	Dim patterns As Map = lang.Get("patterns")
	Dim ci As Boolean = lang.Get("ci")
	For Each cat As String In CATS
		Dim pat As String = ""
		If cat = "keyword" Then
			pat = BuildWordGroup(lang.Get("keywords"), ci)            ' word list, or a pattern fallback
			If pat = "" And patterns.ContainsKey("keyword") Then pat = patterns.Get("keyword")
		Else If cat = "type" Then
			If lang.ContainsKey("types") Then pat = BuildWordGroup(lang.Get("types"), ci)
			If pat = "" And patterns.ContainsKey("type") Then pat = patterns.Get("type")
		Else If patterns.ContainsKey(cat) Then
			pat = patterns.Get(cat)
		End If
		If pat = "" Then Continue
		Dim grp As String = cat.ToUpperCase
		parts.Add($"(?<${grp}>${pat})"$)
		grpNames.Add(grp)
		styleCls.Add(cat)            ' style class name = category (matches the CSS theme)
	Next
	lang.Put("regex", Join(parts, "|"))
	lang.Put("groupNames", grpNames)
	lang.Put("styleClasses", styleCls)
End Sub

Private Sub BuildWordGroup (words As List, ci As Boolean) As String
	If words.IsInitialized = False Or words.Size = 0 Then Return ""
	Dim joined As String = Join(words, "|")
	If ci Then Return $"(?i:\b(${joined})\b)"$
	Return $"\b(${joined})\b"$
End Sub

Private Sub Join (items As List, sep As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	For i = 0 To items.Size - 1
		If i > 0 Then sb.Append(sep)
		sb.Append(items.Get(i))
	Next
	Return sb.ToString
End Sub

Public Sub SetLanguageByExtension (ext As String)
	If mByExt.ContainsKey(ext.ToLowerCase) Then
		mCurrent = mByExt.Get(ext.ToLowerCase)
	Else
		Dim none As Map
		mCurrent = none
	End If
End Sub

' Selects by display name; an unknown name (e.g. "Plain") clears highlighting.
Public Sub SetLanguageByName (name As String)
	Dim none As Map
	mCurrent = none
	For Each lang As Map In mLangs
		If lang.Get("name") = name Then mCurrent = lang
	Next
End Sub

Public Sub CurrentName As String
	If mCurrent.IsInitialized = False Then Return "Plain"
	Return mCurrent.Get("name")
End Sub

Public Sub Names As List
	Dim r As List
	r.Initialize
	For Each lang As Map In mLangs
		r.Add(lang.Get("name"))
	Next
	Return r
End Sub

' Recomputes and applies highlighting for the current language over the editor's text.
Public Sub Highlight (text As String)
	If mCurrent.IsInitialized = False Or text.Length = 0 Then
		mEditor.ClearStyles
		Return
	End If
	Dim gn As List = mCurrent.Get("groupNames")
	Dim sc As List = mCurrent.Get("styleClasses")
	mEditor.ApplyStyleSpans(mCurrent.Get("regex"), ListToArray(gn), ListToArray(sc))
End Sub

Private Sub ListToArray (l As List) As String()
	Dim a(l.Size) As String
	For i = 0 To l.Size - 1
		a(i) = l.Get(i)
	Next
	Return a
End Sub
