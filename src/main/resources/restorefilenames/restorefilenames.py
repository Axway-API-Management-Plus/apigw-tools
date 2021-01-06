import sys
import os
import logging

from optparse import OptionParser
import xml.etree.ElementTree as ET

class ProjectFiles:
    def __init__(self, projdir):
        self.__projdir = projdir
        self.__config_file = os.path.join(self.__projdir, "configs.xml")

        # Check for valid project directory
        logging.info("Restore file names for project '%s'" % (self.__projdir))        
        if not os.path.isfile(self.__config_file):
            raise ValueError("Directory is not a valid project directory (missing 'configs.xml'): %s" % (self.__config_file))
        
        # Read configuration
        logging.info("Reading configuration file: %s" % (self.__config_file))
        self.__config_tree = ET.parse(self.__config_file)

    def __rename_file(self, current_name, new_name):
        logging.info("Rename: %s --> %s" % (current_name, new_name))
        current_path = os.path.join(self.__projdir, current_name)
        new_path = os.path.join(self.__projdir, new_name)
        os.rename(current_path, new_path)

    def __rename_store_files(self, current_base_name, new_base_name):
        current_xml = current_base_name + ".xml"
        current_md5 = current_base_name + ".md5"
        new_xml = new_base_name + ".xml"
        new_md5 = new_base_name + ".md5"

        if current_base_name != new_base_name:
            self.__rename_file(current_xml, new_xml)
            self.__rename_file(current_md5, new_md5)
        else:
            logging.info("%s already restored" % (new_base_name))
        return new_xml

    def __restore_store_file(self, id):
        store = self.__config_tree.getroot().findall("./store[@id='%s']" % (id))[0]
        store_type = store.get('type')
        logging.debug("Restore file of store '%s' of type '%s'" % (id, store_type))

        url = store.findall("./connectionCredentials/credential[@name='url']")[0]
        url.text = self.__rename_store_files(url.text[:-len('.xml')], store_type)

    def restore_names(self):
        root = self.__config_tree.getroot()
        assembly_name = root.get('activeAssembly')
        logging.debug("Using assembly '%s'" % (assembly_name))
        for component in root.findall("assembly[@id='%s']/component" % (assembly_name)):
            self.__restore_store_file(component.get('id'))
        
        self.__config_tree.write(self.__config_file)
        logging.info("configs.xml updated")

def main():
    prog = sys.argv[0]
    version = "%prog 1.0.0"
    usage = "%prog OPTIONS"
    epilog = "Restores the original names of entity store files after running `projupgrade` tool."
 
    parser = OptionParser(usage=usage, version=version, epilog=epilog)
    parser.add_option("-v", "--verbose", dest="verbose", help="Enable verbose messages [optional]", action="store_true")
    parser.add_option("--projdir", dest="projdir", help="Project directory (contains 'configs.xml' file)", metavar="PROJDIR")
    
    (options, args) = parser.parse_args()

    if not options.projdir:
      parser.error("Project directory is missing!")

    try:
        # Configure logging
        logging.basicConfig(format='%(levelname)s: %(message)s')
        if options.verbose:
            logging.getLogger().setLevel(logging.DEBUG)
        else:
            logging.getLogger().setLevel(logging.INFO)

        # Restore file names
        proj = ProjectFiles(options.projdir)
        proj.restore_names()

    except Exception as e:
        if options.verbose:
            logging.error("Error occurred, check details:", exc_info=True)
        else:
            logging.error("%r" % (e))
        sys.exit(1) 

    sys.exit(0)


if __name__ == "__main__":
    main()
