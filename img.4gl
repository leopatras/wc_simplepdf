IMPORT os
MAIN
  OPEN FORM f FROM "img"
  DISPLAY FORM f
  CALL displayPDFUrlBased("hello.pdf")
  MENU
    ON ACTION sample2pages ATTRIBUTE(TEXT="2 Pages")
      CALL displayPDFUrlBased("sample.pdf")
    ON ACTION hello ATTRIBUTE(TEXT="Hello")
      CALL displayPDFUrlBased("hello.pdf")
    COMMAND "Exit"
      EXIT MENU
  END MENU
END MAIN

FUNCTION displayPDFUrlBased(basename STRING)
  DEFINE pdf STRING
  DISPLAY basename TO file
  LET pdf=ui.Interface.filenameToURI(basename)
  DISPLAY "pdf:",pdf
  DISPLAY pdf TO url
  DISPLAY pdf TO imgu
END FUNCTION
