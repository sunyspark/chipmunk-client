# Dark Blue ("Project Chipmunk") Client

A Preservation-Focused Dark Repository for the University of Michigan

## Uploader Setup

- Edit `config/client.yml` to include your API key and the URL to the Chipmunk server.

```yaml
api_key: YOUR_CHIPMUNK_API_KEY
# should be the full URL to the Chipmunk server; defaults to http://localhost:3000
url: http://localhost:3000
```

## Uploader Usage

- `bin/upload -c path/to/config.yml /path/to/bag1 /path/to/bag2`

If no config file is specified, it will use `config/client.yml` by default.

The client will display progress on uploading and validating each bag in sequence.

## Bagging Audio Content

`makebag audio` will create a [BagIt bag](https://tools.ietf.org/id/draft-kunze-bagit-14.txt) and move the files from `source` into `output_bag/data`. It expects there to be a METS file which contains an `mdRef` element that links to a record in [Mirlyn](https://mirlyn.lib.umich.edu); it will download MARC-XML for that record and included it in the bag.

- `bin/makebag audio barcode -s source output_bag`

## Bagging Digital Forensics Content

`makebag digital` will add chipmunk bagging information to an existing bag. The bag should follow the [UMICH disk imaging profile](https://www.umich.edu/~aelkiss/UMICH-Disk-Imaging-profile.json)

- `bin/makebag digital barcode path_to_bag`
