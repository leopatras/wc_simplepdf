IMPORT os
MAIN
  DEFINE parent,url,pdf STRING
  OPEN FORM f FROM "img"
  DISPLAY FORM f
  CALL ui.interface.frontcall(
      "webcomponent", "call", ["formonly.imgh", "getUrl"], [url])
  CALL displayPDFUrlBased(url,"hello.pdf")
  --DISPLAY getUrl("hello.pdf") TO img
  MENU
    ON ACTION sample2pages ATTRIBUTE(TEXT="2 Pages")
      CALL displayPDFUrlBased(url,"sample.pdf")
    ON ACTION hello ATTRIBUTE(TEXT="Hello")
      CALL displayPDFUrlBased(url,"hello.pdf")
      --DISPLAY getUrl("sample.pdf") TO img
    ON ACTION showenv ATTRIBUTE(TEXT = "Show FGL env")
      ERROR "FGL_PUBLIC_DIR:",
        fgl_getenv("FGL_PUBLIC_DIR"),
        ",\nFGL_PUBLIC_URL_PREFIX:",
        fgl_getenv("FGL_PUBLIC_URL_PREFIX"),
        ",\nFGL_PUBLIC_IMAGE_PATH:",
        fgl_getenv("FGL_PUBLIC_IMAGEPATH"),
        ",\npwd:",
        os.Path.pwd(),
        ",\nFGL_PRIVATE_DIR:",
        fgl_getenv("FGL_PRIVATE_DIR")
    COMMAND "Exit"
      EXIT MENU
  END MENU
END MAIN

FUNCTION displayPDFUrlBased(url STRING,basename STRING)
  DEFINE parent,pdf STRING
  --ugly: we need the url of a hidden webco
  --and then move the asset to the location of the hidden webco
  LET parent=os.Path.dirName(url)
  LET pdf=parent,"/",basename
  IF NOT os.Path.copy(basename,"webcomponents/img/"||basename) THEN
    CALL myerr(sfmt("Can't copy asset %1 to webcomponents/img",basename))
  END IF
  DISPLAY "pdf:",pdf
  DISPLAY pdf TO imgu
END FUNCTION

FUNCTION getUrl(fname STRING)
  DEFINE url STRING
  LET url = ui.Interface.filenameToURI(fname)
  DISPLAY url TO url
  RETURN url
END FUNCTION

FUNCTION linkToPublic(fname)
  DEFINE fname, nameToUrl, pubdir, pubimgpath, pubname STRING
  DEFINE progpubdir, programname, remoteName STRING
  DEFINE sepIdx INT
  --GAS sets this variables, to they are only available in GAS mode
  LET pubdir = fgl_getenv("FGL_PUBLIC_DIR")
  DISPLAY "pubdir:", pubdir
  LET nameToUrl = fname
  IF pubdir IS NOT NULL AND os.Path.exists(pubdir) THEN
    LET pubimgpath = fgl_getenv("FGL_PUBLIC_IMAGEPATH")
    --just use the first sub dir in the path if we have more than one
    --the GAS default is "common"
    IF (sepIdx := pubimgpath.getIndexOf(os.Path.pathSeparator(), 1)) > 0 THEN
      LET pubimgpath = pubimgpath.subString(1, sepIdx - 1)
    END IF
    LET pubdir = os.Path.join(pubdir, pubimgpath)
    IF NOT os.Path.exists(pubdir) OR NOT os.Path.isDirectory(pubdir) THEN
      CALL myerr(
        SFMT("Try to link into public GAS directory:%1, but this name either doesn't exist or isn't a directory",
          pubdir))
    END IF
    DISPLAY "pubdir=", pubdir
    LET programname = os.Path.baseName(arg_val(0))
    LET progpubdir = os.Path.join(pubdir, programname)
    IF NOT os.Path.exists(progpubdir) THEN
      --link this programs public dir into the public GAS image dir
      --under the name of the program (note: doesn't work on Windows)
      --for Apache: set Options +FollowSymLinks
      CALL myrun(
        SFMT("ln -s '%1' '%2'", os.Path.fullPath("./public"), progpubdir))
    END IF
    LET pubname = os.Path.join(progpubdir, os.Path.basename(fname))
    --copy our image to the GAS public dir
    --which means anybody knowing the file name can access it
    --if our file name is hello.pdf the http name is then http://localhost:xxx/ua/i/common/img/hello.pdf?t=xxxxxxx
    DISPLAY "use progpubdir:", progpubdir, ",fname:", pubname
    LET nameToUrl = os.Path.join(programname, fname)
  ELSE
    --direct mode: directly use the relative public/hello.pdf name
    LET nameToUrl = os.Path.join("public", fname)
  END IF
  DISPLAY nameToUrl TO nameToUrl
  LET remoteName = ui.Interface.filenameToURI(nameToUrl)
  DISPLAY "remoteName:", remoteName
  RETURN remoteName
END FUNCTION

FUNCTION myerr(errstr STRING)
  DEFINE ch base.Channel
  LET ch = base.Channel.create()
  CALL ch.openFile("<stderr>", "w")
  CALL ch.writeLine(SFMT("ERROR:%1", errstr))
  CALL ch.close()
  EXIT PROGRAM 1
END FUNCTION

FUNCTION myrun(cmd STRING)
  DEFINE cmdOrig, tmpName, errStr STRING
  DEFINE txt TEXT
  DEFINE code INT
  LET cmdOrig = cmd
  IF cmd.getIndexOf(">", 1) == 0 THEN
    --no redirection, we redirect
    LET tmpName = os.Path.makeTempName()
    LET cmd = cmd, " 2>&1 >", tmpName
  END IF
  --DISPLAY "RUN cmd:",cmd
  RUN cmd RETURNING code
  IF code THEN
    IF tmpName IS NOT NULL THEN
      --we did redirect
      LOCATE txt IN FILE tmpName
      LET errStr = ",\n  output:", txt
      CALL os.Path.delete(tmpName) RETURNING code
      CALL myerr(SFMT("failed to RUN:%1%2", cmdOrig, errStr))
    ELSE
      --we didn't redirect
      CALL myerr(SFMT("ERROR:failed to RUN:%1", cmdOrig))
    END IF
  END IF
  IF tmpName IS NOT NULL THEN
    CALL os.Path.delete(tmpName) RETURNING code
  END IF
END FUNCTION
