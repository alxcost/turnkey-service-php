# iReceptor Turnkey

The iReceptor Turnkey is a quick and easy mechanism for researchers to create their own [AIRR Data Commons](https://docs.airr-community.org/en/latest/api/adc.html#datacommons) repository.

## What's in the iReceptor Turnkey?
- a database
- scripts to add data to the database
- a web service exposing the database via the [ADC API](https://docs.airr-community.org/en/latest/api/adc_api.html)

These components are packaged as Docker images. The installation script will download and run these images, after having installed Docker.

[Read more about the iReceptor Turnkey](http://www.ireceptor.org/repositories#turnkey) on the iReceptor website. The remainder of this document only provides installation instructions.

## System requirements

- Linux Ubuntu. The turnkey was tested on Ubuntu 16.04 and 18.04.
- `sudo` without password. It's usually already enabled on virtual machines.

## Installation

Download the code from the `production-v3` branch:

```
git clone --branch production-v3 https://github.com/sfu-ireceptor/turnkey-service-php.git
```

Launch the installation script. Note: multiple Docker images will be downloaded from DockerHub. Total time estimate: 10-30 min.

```
cd turnkey-service-php
scripts/install_turnkey.sh
```

## Check it's working

```
curl --data "{}" "http://localhost/airr/v1/repertoire"
```

This returns the list of repertoires in your database, by querying the web service at `/airr/v1/repertoire`, an [ADC API](https://docs.airr-community.org/en/latest/api/adc_api.html) entry point.


You can also visit <http://localhost> in your browser (replace "localhost" with your server URL if necessary). You'll see the home page for your repository, with information about the ADC API and iReceptor.


## Loading data
The general data loading procedure, for a study which has generated sequence data is to:
1. load the associated repertoire metadata using the [iReceptor Metadata CSV format](https://github.com/sfu-ireceptor/dataloading-curation/tree/master/metadata). Note: it's also possible to use the [AIRR Repertoire Schema JSON format](https://docs.airr-community.org/en/latest/datarep/metadata.html).

2. load the sequence annotations (rearrangements) from IMGT, MiXCR, etc.

## Loading the test data
Load the included test data to familiarize yourself with the data loading procedure. You will delete that test data afterwards.

Note: the test data is a single repertoire with 1000 rearrangements. It's a subset from the study [The Different T-cell Receptor Repertoires in Breast Cancer Tumors, Draining Lymph Nodes, and Adjacent Tissues](https://www.ncbi.nlm.nih.gov/pubmed/28039161) data.

1. **Load the repertoire metadata file** [test_data/PRJNA330606_Wang_1_sample_metadata.csv](test_data/PRJNA330606_Wang_1_sample_metadata.csv).
```
scripts/load_metadata.sh ireceptor test_data/PRJNA330606_Wang_1_sample_metadata.csv
```

Check it worked:
```
curl --data "{}" "http://localhost/airr/v1/repertoire"
```
The repertoire metadata is returned as JSON.

2. **Load the rearrangements file** [test_data/SRR4084215_aa_mixcr_annotation_1000_lines.txt](test_data/SRR4084215_aa_mixcr_annotation_1000_lines.txt):
```
scripts/load_rearrangements.sh mixcr test_data/SRR4084215_aa_mixcr_annotation_1000_lines.txt
```

Check it worked:
```
curl --data "{}" "http://localhost/airr/v1/rearrangement"
```
All of the rearrangement data for the 1000 sequences is returned as JSON.

3. **Verify the data was loaded correctly**:
```
scripts/verify_dataload.sh http://xx.xx.xx.xx/ PRJNA330606 test_data PRJNA330606_Wang_1_sample_metadata.csv mixcr /tmp

scripts/verify_dataload.sh http://server.yourorg.org/ PRJNA330606 test_data PRJNA330606_Wang_1_sample_metadata.csv mixcr /tmp

```
The above command verifies the provenance of the data loaded with the previous commands (`load_metadata.sh`, `load_rearrangements.sh`), assuming that data is loaded a study at a time as described above. The `verify_dataload.sh` command takes as parameters the URL for the service/repository to test, the Study ID (`PRJNA330606`) of the study to test, the directory in which the study metadata and the rearrangement data is stored (`test_data`), the study metadata file within this directory (`PRJNA330606_Wang_1_sample_metadata.csv`), the file format for the rearrangement files (`mixcr` in this case, but should be one of `mixcr`, `vquest`, or `igblast` (igblast includes the airr file format)), and a directory (`/tmp`) in which to generate the data provenance report.  

Note: unlike the loading scripts, `verify_dataload.sh` requires that you provide either an IP number or a fully qualified domain name. Providing `localhost` will not work.

This will output a summary report checking the data that was loaded into the repository against the data that is returned by querying the AIRR Data Commons API and retrieving that data. The report compares all of information in the metadata file against what is returned from the ADC API to confirm the data was loaded and is returned correctly. In addition, the process compares the number of rearrangements in the rearrangement files against the count returned by the the ADC API as well as the ir_curator_count field in the metadata file (should that column exist). 

Hopefully, this process will report no errors. If so, the data was loaded and retrieved correctly. Note that this works with data that is loaded as iReceptor metadata files, and requires the metadata file and the rearrangements be in the same directory. For more information on using the `verify_dataload.sh` script and how to interpret the results of the report please refer to the [Verify Dataloading documentation](doc/sanitychecking.md). 

Note: all of the scripts `load_metadata.sh`, `load_rearrangement.sh`, and `verify_dataload.sh` produce a log file for each file processed in the `log` directory. Log files are named using the current date, followed by the name of the processed file.

That's all, congratulations :relaxed: You can now [reset the turnkey database](doc/resetting.md) and load your own data.

## Loading your own data

Note: use a clearly defined curation process for your data to ensure good provenance. Refer to the [iReceptor Curation](http://www.ireceptor.org/curation) process and the [iReceptor Curation GitHub repository](https://github.com/sfu-ireceptor/dataloading-curation/tree/master) for recommended data curation approaches.

To load your own data, follow the same procedure as with the test data.
Note: make sure your rearrangements files are declared in the repertoire metadata file, under the `data_processing_files` column.

1. Load your repertoire metadata:
```
scripts/load_metadata.sh ireceptor <file path of your CSV or JSON metadata file>
```

2. Load your rearrangements files. You can load multiple files at once:
```
scripts/load_rearrangements.sh mixcr <your study data folder>/*.txt
```
This will load all files ending by `.txt` from your study data folder.

Note: Compressed `.gz` files are supported and can be loaded directly. Example:
```
scripts/load_rearrangements.sh mixcr <your study data folder>/*.gz
```
Note: make sure that the full file name, including the `.gz` extension, was declared in the repertoire metadata file.

### Loading IMGT or AIRR rearrangements

Just replace the `mixcr` parameter by `mixcr_v3`, `imgt` or `airr`. Example:
```
scripts/load_rearrangements.sh imgt <IMGT files>
```


### Loading many rearrangements
:warning: Loading many rearrangements can take hours. We recommend using the Unix command `nohup` to run the script in the background, and to redirect the script output to a log file. So you can log out and come back later to check on the data loading progress by looking at that file. Example:

```
nohup scripts/load_rearrangements.sh mixcr my_study_folder/*.txt > progress.log &
```
### Updating repertoire metadata

Invairably you will need to make a change to the repertoire metadata that you loaded.
There is a simple update_metadata script to perform this for you. As with loading the metadata
you simply tell the script what type of repertoire metadata you are loading (ireceptor or AIRR Repertoire JSON)
and the file. Because this is updating the repository live, there is an option to run the entire script and report
on any updates that the script would perform *without* actually loading any data (--skipload). 

If you edit the test metadata file, and then run:

```
scripts/update_metadata.sh ireceptor --skipload test_data/PRJNA330606_Wang_1_sample_metadata.csv
```
This will  report that it is changing the fields for the repertoire, but it will *not* write those changes to the 
repository. If you are comfortable with the changes it reports then you can rerun the script without the --skipload 
option to make the changes.

:warning: This command will update the database. Before making changes to the repository, you should consider making 
a backup of the database.

```
scripts/update_metadata.sh ireceptor test_data/PRJNA330606_Wang_1_sample_metadata.csv
```

## Backing up the database
When you've loaded your data, we recommend [backing up the database](doc/database_backup.md) to avoid having to load your data again in case a problem happens.

## Other information

### Managing the database
- [Starting and stopping the Turnkey](doc/start_stop_turnkey.md)
- [Running a production Turnkey](doc/production_db.md)
- [Moving the database to another folder](doc/moving_the_database_folder.md)
- [Using an external volume](doc/using_an_external_volume.md)
- [Backing up and restoring the database](doc/database_backup.md)
- [Resetting the turnkey database](doc/resetting.md)

### Managing the turnkey
- [How the turnkey works](doc/how_it_works.md)
- [Updating the turnkey](doc/updating.md)
- [Web statistics](doc/web_stats.md)

### If something looks wrong
- [Troubleshooting](doc/troubleshooting.md) :hammer:

## Contact us
:envelope: <support@ireceptor.org>
