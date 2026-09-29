Sub FlagPriorityConversations()
    '
    ' HOW TO USE:
    ' 1. Create a sheet called "Priority" in this workbook
    ' 2. Paste conversation IDs in column A (one per row)
    ' 3. Run this macro
    ' 4. Column A on the data sheet gets "YES" for flagged conversations
    '

    ' Check that Priority sheet exists
    Dim pSheet As Worksheet
    On Error Resume Next
    Set pSheet = ThisWorkbook.Sheets("Priority")
    On Error GoTo 0

    If pSheet Is Nothing Then
        MsgBox "Create a sheet called ""Priority"" and paste conversation IDs in column A.", vbExclamation
        Exit Sub
    End If

    ' Read IDs from Priority sheet column A
    Dim idCount As Long
    idCount = 0
    Dim lastIdRow As Long
    lastIdRow = pSheet.Cells(pSheet.Rows.Count, 1).End(xlUp).Row

    ' Store IDs in an array
    If lastIdRow < 1 Then
        MsgBox "No IDs found in the Priority sheet. Paste them in column A.", vbExclamation
        Exit Sub
    End If

    Dim idList() As String
    ReDim idList(1 To lastIdRow)

    Dim i As Long
    For i = 1 To lastIdRow
        Dim val As String
        val = Trim(CStr(pSheet.Cells(i, 1).Value))
        If Len(val) > 0 Then
            idCount = idCount + 1
            idList(idCount) = val
        End If
    Next i

    If idCount = 0 Then
        MsgBox "No IDs found in the Priority sheet. Paste them in column A.", vbExclamation
        Exit Sub
    End If

    ' Find the data sheet (first sheet that is not "Priority")
    Dim ws As Worksheet
    Dim s As Worksheet
    For Each s In ThisWorkbook.Sheets
        If s.Name <> "Priority" Then
            Set ws = s
            Exit For
        End If
    Next s

    ' Find header row containing "External Record Id"
    Dim headerRow As Long
    Dim idCol As Long
    Dim flagCol As Long
    headerRow = 0

    For i = 1 To 20
        Dim cellVal As String
        cellVal = Trim(CStr(ws.Cells(i, 2).Value))
        If InStr(cellVal, "External Record Id") > 0 Then
            headerRow = i
            idCol = 2  ' Column B
            flagCol = 1 ' Column A
            Exit For
        End If
    Next i

    If headerRow = 0 Then
        MsgBox "Could not find header row with 'External Record Id' on sheet '" & ws.Name & "'.", vbExclamation
        Exit Sub
    End If

    ' Add header in column A
    ws.Cells(headerRow, flagCol).Value = "Priority"
    ws.Cells(headerRow, flagCol).Font.Bold = True

    ' Loop through data rows and flag matches
    Dim lastRow As Long
    lastRow = ws.Cells(ws.Rows.Count, idCol).End(xlUp).Row
    Dim flagged As Long
    flagged = 0

    Dim j As Long
    For i = headerRow + 1 To lastRow
        Dim rowId As String
        rowId = Trim(CStr(ws.Cells(i, idCol).Value))

        If Len(rowId) > 0 Then
            ' Check against ID list
            For j = 1 To idCount
                If rowId = idList(j) Then
                    ws.Cells(i, flagCol).Value = "YES"
                    ws.Cells(i, flagCol).Font.Bold = True
                    ws.Cells(i, flagCol).Font.Color = RGB(255, 255, 255)
                    ws.Cells(i, flagCol).Interior.Color = RGB(231, 49, 38)
                    flagged = flagged + 1
                    Exit For
                End If
            Next j
        End If
    Next i

    ' Auto-fit column A
    ws.Columns(flagCol).AutoFit

    MsgBox "Done! Flagged " & flagged & " conversations out of " & idCount & " IDs provided.", vbInformation

End Sub
