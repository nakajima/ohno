source = ["./ohno"]
bundle_id = "fm.folder.ohno"

sign {
  
}

zip {
  output_path = "ohno.zip"
}

notarize {
  path = "./ohno.zip"
  bundle_id = "fm.folder.ohno"
}
