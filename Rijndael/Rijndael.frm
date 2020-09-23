VERSION 5.00
Begin VB.Form fRijndael 
   Caption         =   "Form1"
   ClientHeight    =   6015
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   10065
   LinkTopic       =   "Form1"
   ScaleHeight     =   6015
   ScaleWidth      =   10065
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton cmdSizeTest 
      Caption         =   "Size Test"
      Height          =   375
      Left            =   8640
      TabIndex        =   14
      Top             =   5520
      Visible         =   0   'False
      Width           =   1215
   End
   Begin VB.CheckBox chkTerminal 
      Caption         =   "Terminal Font"
      Height          =   255
      Left            =   2760
      TabIndex        =   13
      Top             =   5520
      Width           =   1815
   End
   Begin VB.CommandButton cmdFileDecrypt 
      Caption         =   "Decrypt File"
      Height          =   495
      Left            =   1320
      TabIndex        =   12
      Top             =   5280
      Width           =   1095
   End
   Begin VB.CommandButton cmdFileEncrypt 
      Caption         =   "Encrypt File"
      Height          =   495
      Left            =   120
      TabIndex        =   11
      Top             =   5280
      Width           =   1095
   End
   Begin VB.CheckBox Check1 
      Caption         =   "Plaintext is hex"
      Height          =   255
      Left            =   2760
      TabIndex        =   10
      Top             =   5160
      Visible         =   0   'False
      Width           =   1815
   End
   Begin VB.ComboBox cboKeySize 
      Height          =   315
      Left            =   6360
      Style           =   2  'Dropdown List
      TabIndex        =   6
      Top             =   5520
      Width           =   1695
   End
   Begin VB.ComboBox cboBlockSize 
      Height          =   315
      Left            =   6360
      Style           =   2  'Dropdown List
      TabIndex        =   5
      Top             =   5160
      Width           =   1695
   End
   Begin VB.TextBox txtPassword 
      Height          =   285
      Left            =   6360
      TabIndex        =   4
      Text            =   "Password Passphrase"
      Top             =   4800
      Width           =   3495
   End
   Begin VB.CommandButton cmdDecrypt 
      Caption         =   "Decrypt"
      Height          =   495
      Left            =   1320
      TabIndex        =   3
      Top             =   4680
      Width           =   1095
   End
   Begin VB.CommandButton cmdEncrypt 
      Caption         =   "Encrypt"
      Height          =   495
      Left            =   120
      TabIndex        =   2
      Top             =   4680
      Width           =   1095
   End
   Begin VB.Frame Frame1 
      Caption         =   "Data"
      Height          =   4455
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   9735
      Begin VB.TextBox Text1 
         Height          =   3855
         Left            =   240
         MultiLine       =   -1  'True
         ScrollBars      =   2  'Vertical
         TabIndex        =   1
         Top             =   360
         Width           =   9255
      End
   End
   Begin VB.Label Label3 
      Caption         =   "Key Size:"
      Height          =   255
      Left            =   4920
      TabIndex        =   9
      Top             =   5520
      Width           =   1455
   End
   Begin VB.Label Label2 
      Caption         =   "Block Size:"
      Height          =   255
      Left            =   4920
      TabIndex        =   8
      Top             =   5160
      Width           =   1455
   End
   Begin VB.Label Label1 
      Caption         =   "Passphrase:"
      Height          =   255
      Left            =   4920
      TabIndex        =   7
      Top             =   4800
      Width           =   1455
   End
End
Attribute VB_Name = "fRijndael"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

Option Explicit


#Const SUPPORT_LEVEL = 0     'Default=0
'Must be equal to SUPPORT_LEVEL in cRijndael

'An instance of the Class
Private m_Rijndael As New cRijndael


'Used to display what the program is doing in the Form's caption
Public Property Let Status(TheStatus As String)
    If Len(TheStatus) = 0 Then
        Me.Caption = App.Title
    Else
        Me.Caption = App.Title & " - " & TheStatus
    End If
    Me.Refresh
End Property


'Assign TheString to the Text property of TheTextBox if possible.  Otherwise give warning.
Private Sub DisplayString(TheTextBox As TextBox, ByVal TheString As String)
    If Len(TheString) < 65536 Then
        TheTextBox.Text = TheString
    Else
        MsgBox "Can not assign a String larger than 64k " & vbCrLf & _
               "to the Text property of a TextBox control." & vbCrLf & _
               "If you need to support Strings longer than 64k," & vbCrLf & _
               "you can use a RichTextBox control instead.", vbInformation
    End If
End Sub


'Returns a String containing Hex values of data(0 ... n-1) in groups of k
Private Function HexDisplay(data() As Byte, n As Long, k As Long) As String
    Dim i As Long
    Dim j As Long
    Dim c As Long
    Dim data2() As Byte

    If LBound(data) = 0 Then
        ReDim data2(n * 4 - 1 + ((n - 1) \ k) * 4)
        j = 0
        For i = 0 To n - 1
            If i Mod k = 0 Then
                If i <> 0 Then
                    data2(j) = 32
                    data2(j + 2) = 32
                    j = j + 4
                End If
            End If
            c = data(i) \ 16&
            If c < 10 Then
                data2(j) = c + 48     ' "0"..."9"
            Else
                data2(j) = c + 55     ' "A"..."F"
            End If
            c = data(i) And 15&
            If c < 10 Then
                data2(j + 2) = c + 48 ' "0"..."9"
            Else
                data2(j + 2) = c + 55 ' "A"..."F"
            End If
            j = j + 4
        Next i
Debug.Assert j = UBound(data2) + 1
        HexDisplay = data2
    End If

End Function


'Reverse of HexDisplay.  Given a String containing Hex values, convert to byte array data()
'Returns number of bytes n in data(0 ... n-1)
Private Function HexDisplayRev(TheString As String, data() As Byte) As Long
    Dim i As Long
    Dim j As Long
    Dim c As Long
    Dim d As Long
    Dim n As Long
    Dim data2() As Byte

    n = 2 * Len(TheString)
    data2 = TheString

    ReDim data(n \ 4 - 1)

    d = 0
    i = 0
    j = 0
    Do While j < n
        c = data2(j)
        Select Case c
        Case 48 To 57    '"0" ... "9"
            If d = 0 Then   'high
                d = c
            Else            'low
                data(i) = (c - 48) Or ((d - 48) * 16&)
                i = i + 1
                d = 0
            End If
        Case 65 To 70   '"A" ... "F"
            If d = 0 Then   'high
                d = c - 7
            Else            'low
                data(i) = (c - 55) Or ((d - 48) * 16&)
                i = i + 1
                d = 0
            End If
        Case 97 To 102  '"a" ... "f"
            If d = 0 Then   'high
                d = c - 39
            Else            'low
                data(i) = (c - 87) Or ((d - 48) * 16&)
                i = i + 1
                d = 0
            End If
        End Select
        j = j + 2
    Loop
    n = i
    If n = 0 Then
        Erase data
    Else
        ReDim Preserve data(n - 1)
    End If
    HexDisplayRev = n

End Function


'Returns a byte array containing the password in the txtPassword TextBox control.
'If "Plaintext is hex" is checked, and the TextBox contains a Hex value the correct
'length for the current KeySize, the Hex value is used.  Otherwise, ASCII values
'of the txtPassword characters are used.
Private Function GetPassword() As Byte()
    Dim data() As Byte

    If Check1.Value = 0 Then
        data = StrConv(txtPassword.Text, vbFromUnicode)
        ReDim Preserve data(31)
    Else
        If HexDisplayRev(txtPassword.Text, data) <> (cboKeySize.ItemData(cboKeySize.ListIndex) \ 8) Then
            data = StrConv(txtPassword.Text, vbFromUnicode)
            ReDim Preserve data(31)
        End If
    End If
    GetPassword = data
End Function


Private Sub cmdEncrypt_Click()
    Dim pass()        As Byte
    Dim plaintext()   As Byte
    Dim ciphertext()  As Byte
    Dim KeyBits       As Long
    Dim BlockBits     As Long

    If Len(Text1.Text) = 0 Then
        MsgBox "No Plaintext"
    Else
        If Len(txtPassword.Text) = 0 Then
            MsgBox "No Password"
        Else
            KeyBits = cboKeySize.ItemData(cboKeySize.ListIndex)
            BlockBits = cboBlockSize.ItemData(cboBlockSize.ListIndex)
            pass = GetPassword

            Status = "Converting Text"
            If Check1.Value = 0 Then
                plaintext = StrConv(Text1.Text, vbFromUnicode)
            Else
                If HexDisplayRev(Text1.Text, plaintext) = 0 Then
                    MsgBox "Text not Hex data"
                    Status = ""
                    Exit Sub
                End If
            End If

            Status = "Encrypting Data"
#If SUPPORT_LEVEL Then
            m_Rijndael.SetCipherKey pass, KeyBits, BlockBits
            m_Rijndael.ArrayEncrypt plaintext, ciphertext, 0, BlockBits
#Else
            m_Rijndael.SetCipherKey pass, KeyBits
            m_Rijndael.ArrayEncrypt plaintext, ciphertext, 0
#End If
            Status = "Converting Text"
            DisplayString Text1, HexDisplay(ciphertext, UBound(ciphertext) + 1, BlockBits \ 8)
            Status = ""
        End If
    End If
End Sub
Private Sub cmdDecrypt_Click()
    Dim pass()        As Byte
    Dim plaintext()   As Byte
    Dim ciphertext()  As Byte
    Dim KeyBits       As Long
    Dim BlockBits     As Long

    If Len(Text1.Text) = 0 Then
        MsgBox "No Ciphertext"
    Else
        If Len(txtPassword.Text) = 0 Then
            MsgBox "No Password"
        Else
            KeyBits = cboKeySize.ItemData(cboKeySize.ListIndex)
            BlockBits = cboBlockSize.ItemData(cboBlockSize.ListIndex)
            pass = GetPassword

            Status = "Converting Text"
            If HexDisplayRev(Text1.Text, ciphertext) = 0 Then
                MsgBox "Text not Hex data"
                Status = ""
                Exit Sub
            End If

            Status = "Decrypting Data"
#If SUPPORT_LEVEL Then
            m_Rijndael.SetCipherKey pass, KeyBits, BlockBits
            If m_Rijndael.ArrayDecrypt(plaintext, ciphertext, 0, BlockBits) <> 0 Then
                Status = ""
                Exit Sub
            End If
#Else
            m_Rijndael.SetCipherKey pass, KeyBits
            If m_Rijndael.ArrayDecrypt(plaintext, ciphertext, 0) <> 0 Then
                Status = ""
                Exit Sub
            End If
#End If
            Status = "Converting Text"
            If Check1.Value = 0 Then
                DisplayString Text1, StrConv(plaintext, vbUnicode)
            Else
                DisplayString Text1, HexDisplay(plaintext, UBound(plaintext) + 1, BlockBits \ 8)
            End If
            Status = ""
        End If
    End If
End Sub


Private Sub cmdFileEncrypt_Click()
    Dim FileName  As String
    Dim FileName2 As String
    Dim pass()    As Byte
    Dim KeyBits   As Long
    Dim BlockBits As Long

    If Len(txtPassword.Text) = 0 Then
        MsgBox "No Password"
    Else
        FileName = FileDialog(Me, False, "File to Encrypt", "*.*|*.*")
        If Len(FileName) <> 0 Then
            FileName2 = FileDialog(Me, True, "Save Encrypted Data As ...", "*.aes|*.aes|*.*|*.*", FileName & ".aes")
            If Len(FileName2) <> 0 Then
                RidFile FileName2
                KeyBits = cboKeySize.ItemData(cboKeySize.ListIndex)
                BlockBits = cboBlockSize.ItemData(cboBlockSize.ListIndex)
                pass = GetPassword

                Status = "Encrypting File"
#If SUPPORT_LEVEL Then
                m_Rijndael.SetCipherKey pass, KeyBits, BlockBits
                m_Rijndael.FileEncrypt FileName, FileName2, BlockBits
#Else
                m_Rijndael.SetCipherKey pass, KeyBits
                m_Rijndael.FileEncrypt FileName, FileName2
#End If
                Status = ""
            End If
        End If
    End If
End Sub
Private Sub cmdFileDecrypt_Click()
    Dim FileName  As String
    Dim FileName2 As String
    Dim pass()    As Byte
    Dim KeyBits   As Long
    Dim BlockBits As Long

    If Len(txtPassword.Text) = 0 Then
        MsgBox "No Password"
    Else
        FileName = FileDialog(Me, False, "File to Decrypt", "*.aes|*.aes|*.*|*.*")
        If Len(FileName) <> 0 Then
            If InStrRev(FileName, ".aes") = Len(FileName) - 3 Then FileName2 = Left$(FileName, Len(FileName) - 4)
            FileName2 = FileDialog(Me, True, "Save Decrypted Data As ...", "*.*|*.*", FileName2)
            If Len(FileName2) <> 0 Then
                RidFile FileName2
                KeyBits = cboKeySize.ItemData(cboKeySize.ListIndex)
                BlockBits = cboBlockSize.ItemData(cboBlockSize.ListIndex)
                pass = GetPassword

                Status = "Decrypting File"
#If SUPPORT_LEVEL Then
                m_Rijndael.SetCipherKey pass, KeyBits, BlockBits
                m_Rijndael.FileDecrypt FileName2, FileName, BlockBits
#Else
                m_Rijndael.SetCipherKey pass, KeyBits
                m_Rijndael.FileDecrypt FileName2, FileName
#End If
                Status = ""
            End If
        End If
    End If
End Sub


Private Sub chkTerminal_Click()
    Static Text1FontName As String
    Static Text1FontBold As Boolean
    Static Text1FontSize As Long

    If chkTerminal.Value = 0 Then
        Text1.FontName = Text1FontName
        Text1.FontBold = Text1FontBold
        Text1.FontSize = Text1FontSize
    Else
        Text1FontName = Text1.FontName
        Text1FontBold = Text1.FontBold
        Text1FontSize = Text1.FontSize
        Text1.FontName = "Terminal"
    End If
End Sub

Private Sub Form_Initialize()

    cboBlockSize.AddItem "128 Bit"
    cboBlockSize.ItemData(cboBlockSize.NewIndex) = 128
#If SUPPORT_LEVEL = 0 Then
    cboBlockSize.Enabled = False
#Else
#If SUPPORT_LEVEL = 2 Then
    cboBlockSize.AddItem "160 Bit"
    cboBlockSize.ItemData(cboBlockSize.NewIndex) = 160
    cmdSizeTest.Visible = True
#End If
    cboBlockSize.AddItem "192 Bit"
    cboBlockSize.ItemData(cboBlockSize.NewIndex) = 192
#If SUPPORT_LEVEL = 2 Then
    cboBlockSize.AddItem "224 Bit"
    cboBlockSize.ItemData(cboBlockSize.NewIndex) = 224
#End If
    cboBlockSize.AddItem "256 Bit"
    cboBlockSize.ItemData(cboBlockSize.NewIndex) = 256
#End If
    cboKeySize.AddItem "128 Bit"
    cboKeySize.ItemData(cboKeySize.NewIndex) = 128
#If SUPPORT_LEVEL = 2 Then
    cboKeySize.AddItem "160 Bit"
    cboKeySize.ItemData(cboKeySize.NewIndex) = 160
#End If
    cboKeySize.AddItem "192 Bit"
    cboKeySize.ItemData(cboKeySize.NewIndex) = 192
#If SUPPORT_LEVEL = 2 Then
    cboKeySize.AddItem "224 Bit"
    cboKeySize.ItemData(cboKeySize.NewIndex) = 224
#End If
    cboKeySize.AddItem "256 Bit"
    cboKeySize.ItemData(cboKeySize.NewIndex) = 256
    cboBlockSize.ListIndex = 0
    cboKeySize.ListIndex = 0
    txtPassword = "My Password"
    Status = ""

End Sub


'COMPLIANCE TESTING
'
'There are many AES and Rijndael Test Vector Files available on the internet so you can
'verify that an implementation is correct.  Below is a simple test that encrypts and
'decrypts one block for each of the 25 combinations of block and key size.  These test
'vectors were created by Dr Brian Gladman.
'
'If the "Plaintext is hex" CheckBox is checked, plaintext is read and written as Hex values,
'just like the ciphertext.  Also, you can enter a Hex value in the txtPassword TextBox.
'To use the "Plaintext is hex" CheckBox, you need to make it visible yourself.  Then you
'can "cut and paste" data directly from known answer test value files.
'
'I've done a reasonable amount of compliance testing, including a few (10,000 iteration) monte
'carlo tests.  I am fairly certain that the class is 100% compliant.  If you find any problems
'or strange behavior, please let me know so it can be corrected.
'
#If SUPPORT_LEVEL = 2 Then
Private Sub TestStuff(plaintext As String, passtext As String, ciphertext As String)
    Dim k As Long
    Dim p1() As Byte
    Dim c1() As Byte
    Dim cdata() As Byte
    Dim pdata() As Byte
    Dim pass() As Byte
    Dim Nk As Long
    Dim Nb As Long
    Dim n As Long

    k = HexDisplayRev(passtext, pass)
    Nk = k \ 4
    If Nk * 4 <> k Or Nk < 4 Or Nk > 8 Then Exit Sub

    n = HexDisplayRev(plaintext, pdata)
    Nb = n \ 4
    If Nb * 4 <> n Or Nb < 4 Or Nb > 8 Then Exit Sub

    If n <> HexDisplayRev(ciphertext, cdata) Then Exit Sub

    m_Rijndael.SetCipherKey pass, Nk * 32, Nb * 32
    m_Rijndael.ArrayEncrypt pdata, c1, 0, Nb * 32
    m_Rijndael.ArrayDecrypt p1, cdata, 0, Nb * 32

    Text1.Text = Text1.Text & vbCrLf & "ENCRYPT TEST  " & CStr(Nb * 4) & " byte block, " & CStr(Nk * 4) & " byte key" & vbCrLf
    Text1.Text = Text1.Text & "KEY:          " & passtext & IIf(UCase$(passtext) = HexDisplay(pass, Nk * 4, Nk * 4), " = ", "<>") & vbCrLf & String(14, 32) & HexDisplay(pass, Nk * 4, Nk * 4) & vbCrLf
    Text1.Text = Text1.Text & "PLAINTEXT:    " & plaintext & IIf(UCase$(plaintext) = HexDisplay(p1, Nb * 4, Nb * 4), " = ", "<>") & vbCrLf & String(14, 32) & HexDisplay(p1, Nb * 4, Nb * 4) & vbCrLf
    Text1.Text = Text1.Text & "CIPHERTEXT:   " & ciphertext & IIf(UCase$(ciphertext) = HexDisplay(c1, Nb * 4, Nb * 4), " = ", "<>") & vbCrLf & String(14, 32) & HexDisplay(c1, Nb * 4, Nb * 4) & vbCrLf

End Sub
Private Sub cmdSizeTest_Click()
    Text1.Text = ""
    chkTerminal.Value = 1

    TestStuff "3243f6a8885a308d313198a2e0370734", "2b7e151628aed2a6abf7158809cf4f3c", "3925841d02dc09fbdc118597196a0b32"
    TestStuff "3243f6a8885a308d313198a2e0370734", "2b7e151628aed2a6abf7158809cf4f3c762e7160", "231d844639b31b412211cfe93712b880"
    TestStuff "3243f6a8885a308d313198a2e0370734", "2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da5", "f9fb29aefc384a250340d833b87ebc00"
    TestStuff "3243f6a8885a308d313198a2e0370734", "2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d90", "8faa8fe4dee9eb17caa4797502fc9d3f"
    TestStuff "3243f6a8885a308d313198a2e0370734", "2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfe", "1a6e6c2c662e7da6501ffb62bc9e93f3"

    TestStuff "3243f6a8885a308d313198a2e03707344a409382", "2b7e151628aed2a6abf7158809cf4f3c", "16e73aec921314c29df905432bc8968ab64b1f51"
    TestStuff "3243f6a8885a308d313198a2e03707344a409382", "2b7e151628aed2a6abf7158809cf4f3c762e7160", "0553eb691670dd8a5a5b5addf1aa7450f7a0e587"
    TestStuff "3243f6a8885a308d313198a2e03707344a409382", "2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da5", "73cd6f3423036790463aa9e19cfcde894ea16623"
    TestStuff "3243f6a8885a308d313198a2e03707344a409382", "2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d90", "601b5dcd1cf4ece954c740445340bf0afdc048df"
    TestStuff "3243f6a8885a308d313198a2e03707344a409382", "2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfe", "579e930b36c1529aa3e86628bacfe146942882cf"

    TestStuff "3243f6a8885a308d313198a2e03707344a4093822299f31d", "2b7e151628aed2a6abf7158809cf4f3c", "b24d275489e82bb8f7375e0d5fcdb1f481757c538b65148a"
    TestStuff "3243f6a8885a308d313198a2e03707344a4093822299f31d", "2b7e151628aed2a6abf7158809cf4f3c762e7160", "738dae25620d3d3beff4a037a04290d73eb33521a63ea568"
    TestStuff "3243f6a8885a308d313198a2e03707344a4093822299f31d", "2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da5", "725ae43b5f3161de806a7c93e0bca93c967ec1ae1b71e1cf"
    TestStuff "3243f6a8885a308d313198a2e03707344a4093822299f31d", "2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d90", "bbfc14180afbf6a36382a061843f0b63e769acdc98769130"
    TestStuff "3243f6a8885a308d313198a2e03707344a4093822299f31d", "2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfe", "0ebacf199e3315c2e34b24fcc7c46ef4388aa475d66c194c"

    TestStuff "3243f6a8885a308d313198a2e03707344a4093822299f31d0082efa9", "2b7e151628aed2a6abf7158809cf4f3c", "b0a8f78f6b3c66213f792ffd2a61631f79331407a5e5c8d3793aceb1"
    TestStuff "3243f6a8885a308d313198a2e03707344a4093822299f31d0082efa9", "2b7e151628aed2a6abf7158809cf4f3c762e7160", "08b99944edfce33a2acb131183ab0168446b2d15e958480010f545e3"
    TestStuff "3243f6a8885a308d313198a2e03707344a4093822299f31d0082efa9", "2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da5", "be4c597d8f7efe22a2f7e5b1938e2564d452a5bfe72399c7af1101e2"
    TestStuff "3243f6a8885a308d313198a2e03707344a4093822299f31d0082efa9", "2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d90", "ef529598ecbce297811b49bbed2c33bbe1241d6e1a833dbe119569e8"
    TestStuff "3243f6a8885a308d313198a2e03707344a4093822299f31d0082efa9", "2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfe", "02fafc200176ed05deb8edb82a3555b0b10d47a388dfd59cab2f6c11"

    TestStuff "3243f6a8885a308d313198a2e03707344a4093822299f31d0082efa98ec4e6c8", "2b7e151628aed2a6abf7158809cf4f3c", "7d15479076b69a46ffb3b3beae97ad8313f622f67fedb487de9f06b9ed9c8f19"
    TestStuff "3243f6a8885a308d313198a2e03707344a4093822299f31d0082efa98ec4e6c8", "2b7e151628aed2a6abf7158809cf4f3c762e7160", "514f93fb296b5ad16aa7df8b577abcbd484decacccc7fb1f18dc567309ceeffd"
    TestStuff "3243f6a8885a308d313198a2e03707344a4093822299f31d0082efa98ec4e6c8", "2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da5", "5d7101727bb25781bf6715b0e6955282b9610e23a43c2eb062699f0ebf5887b2"
    TestStuff "3243f6a8885a308d313198a2e03707344a4093822299f31d0082efa98ec4e6c8", "2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d90", "d56c5a63627432579e1dd308b2c8f157b40a4bfb56fea1377b25d3ed3d6dbf80"
    TestStuff "3243f6a8885a308d313198a2e03707344a4093822299f31d0082efa98ec4e6c8", "2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfe", "a49406115dfb30a40418aafa4869b7c6a886ff31602a7dd19c889dc64f7e4e7a"

End Sub
#End If
