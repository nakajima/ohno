source = ["./ohno"]
bundle_id = "fm.folder.ohno"

zip {
  output_path = "ohno.zip"
}

notarize {
  path = "./ohno.zip"
  bundle_id = "fm.folder.ohno"
}
