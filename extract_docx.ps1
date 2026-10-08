$word = New-Object -ComObject Word.Application
$word.Visible = $false
$doc = $word.Documents.Open("c:\Users\saksh\Downloads\icloud assessment\Support Engineer AI - Candidate Technical Assignment.docx")
$text = $doc.Content.Text
$doc.Close(0)
$word.Quit(0)
$text | Out-File -FilePath "c:\Users\saksh\Downloads\icloud assessment\docx_content.txt" -Encoding UTF8
