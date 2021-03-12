from urllib.request import urlopen
from urllib.parse import urlparse
import os, typing, random
import pandas as pd
import random
import sys

# [+] Pobierz dane.
# [+] Zlicz rekordy.
# Losuj n z nich.
# Zapisz do CSV korzystając z template.

ROOT_DIR_PATH = "./generatorka/"
SURNAMES_SOURCE = [
    "http://api.dane.gov.pl/media/resources/20210203/nazwiska_m%C4%99skie-z_uwzgl%C4%99dnieniem_os%C3%B3b_zmar%C5%82ych.csv",
    "http://api.dane.gov.pl/media/resources/20210203/nazwiska_%C5%BCe%C5%84skie-z_uwzgl%C4%99dnieniem_os%C3%B3b_zmar%C5%82ych.csv"
]
# 0 - zenskie
# 1 - meskie
FIRST_NAMES_SOURCE = [
    (0, "~/Desktop/generatorka/izenskie.csv"),
    (1, "~/Desktop/generatorka/imeskie.csv")
]
ADDRESS_SOURCE = [
    "~/Desktop/generatorka/nxr-hp-got-200801.xlsx"
]


class Source:
    url: str
    filepath: str
    filename: str

    def __init__(self, url: str):
        self.url = url
        self.filename = self.get_filename()
        self.filepath = ROOT_DIR_PATH + self.filename

    def fetch(self):
        print("Fetching %s..." % self.url)

        if self.filepath[-5:-1] == "xlsx" or self.filepath[-4:-1] == "xls":
            csv_file = ROOT_DIR_PATH + self.filename[:self.filename.rfind(".")] + ".csv"
            self.filepath = csv_file
            if os.path.exists(csv_file):
                print("File has been already fetched.")
                return

            excel_file = pd.read_excel(self.url, engine='openpyxl')
            excel_file.to_csv(csv_file)
            return

        if os.path.exists(self.filepath):
            print("File has been already fetched.")
            return
        
        import ssl
        ctx_no_secure = ssl.create_default_context()
        ctx_no_secure.set_ciphers('HIGH:!DH:!aNULL')
        ctx_no_secure.check_hostname = False
        ctx_no_secure.verify_mode = ssl.CERT_NONE

        with urlopen(self.url, context=ctx_no_secure) as u:
            with open(self.filepath, "wb") as f:
                f.write(u.read())
        print("Fetched!")

    def get_filename(self):
        filename = None
        try:
            new_url = self.url
            if self.url[-1] == '/':
                new_url = self.url[:-1]
            filename = new_url[new_url.rindex('/')+1:]
        except ValueError:
            print("The url (%s) seems to be incorrect." % self.url)
        finally:
            return filename


class DataStore:
    def __init__(self):
        self.lines = []
        self.line_cnt = 0

    def add(self, src: Source):
        src.fetch()

        cnt = 0
        offset = 1
        with open(src.filepath, "rb") as f:
            for x in f:
                if offset > 0:
                    offset -= 1
                    continue
                cnt += 1
                self.lines.append(x)


        self.line_cnt += cnt - offset
        print("Added %d lines." % (cnt - offset))
    
    def get_line(self, i: int):
        return self.lines[i].decode('utf-8')

    def rand(self):
        return self.get_line(random.randint(0, self.line_cnt-1))
    
    def __str__(self):
        return "DataStore(line_cnt=%d)" % (self.line_cnt)


class Address:
    def __init__(self, city, prefecture, postcode, country, street, street_nr):
        self.city = city.title()
        self.prefecture = prefecture.lower()
        self.postcode = postcode
        self.country = country.title()
        self.address = street.title() + " " + street_nr.upper()
    
    def __str__(self):
        return self.address + "\";\"" + self.city + "\";\"" + self.prefecture + "\";\"" + self.postcode + "\";\"" + self.country


class AddressDataStore(DataStore):
    def get_line(self, i: int):
        x = super().get_line(i).split(",")

        postcode = "%02d-%03d" % (random.randint(0, 100), random.randint(0, 1000))
        return str(Address(x[7], x[1], postcode, "Polska", x[9], x[10]))


class NameDataStore(DataStore):
    def get_line(self, i: int):
        x = super().get_line(i).split(",")
        return x[0].title()


class SurnameDataStore(DataStore):
    def get_line(self, i: int):
        x = super().get_line(i).split(",")
        return x[0].title()


surname_store = SurnameDataStore()
address_store = AddressDataStore()
# 0 - zenskie
# 1 - meskie
name_store = [NameDataStore(), NameDataStore()]


def gen_pesel(sex: int):
    yob = random.randint(1950, 2016) 
    dob = random.randint(1, 28)
    mob = random.randint(1, 12)
    nr = random.randint(1, 999)
    s = random.randint(0, 9)

    if yob >= 2000:
        mob += 20

    return "%d%02d%02d%03d%d%d" % (
        yob % 100,
        mob,
        dob,
        nr,
        sex,
        s,
    ) 

ID_START = 2137000
id_last = ID_START
def generate_record():
    global id_last
    domains = ["@gmail.com", "@wp.pl", "@o2.pl", "@hotmail.com", "@protonmail.com"]

    rid = id_last
    id_last += 1

    sex = random.randint(0, 1)
    surname, name = surname_store.rand().title(), name_store[sex].rand().title()
    email = "%s.%s%s" % (name.encode("ascii", errors="ignore").decode().lower().replace(" ", "-"),
            surname.encode("ascii", errors="ignore").decode().lower().replace(" ", "-"),
            domains[random.randint(0, 3)])

    return "%d;\"%s\";\"%s\";%d;%s;%d;\"%s\";\"%s\";\"%s\";\"%s\";%d;\"%s\";\"%s\";%d;\"%s\";\"%s\";\"%s\"" % (
            rid,
            surname, name, random.randint(0, 3000), gen_pesel(sex),
            random.randint(1000000000, 9999999999), name_store[1].rand(),
            name_store[0].rand(), surname_store.rand(), email, 
            random.randint(100000000, 999999999), str(address_store.rand()),
            "", random.randint(0, 1), "", email[:email.find("@")].replace(".", "-") + ".pl",
            ("Mężczyzna" if sex == 1 else "Kobieta"))
    

if __name__ == "__main__":
    if not os.path.exists(ROOT_DIR_PATH):
        os.mkdir(ROOT_DIR_PATH)

    for x in ADDRESS_SOURCE:
        address_store.add(Source(x))
    for x in SURNAMES_SOURCE:
        surname_store.add(Source(x))
    for x in FIRST_NAMES_SOURCE:
        name_store[x[0]].add(Source(x[1]))
    print("===============================", "Generating a random set of data...", sep="\n")

    for i in range(1, int(sys.argv[2]) + 1):
        with open(ROOT_DIR_PATH + "out" + str(i) + ".csv", "w") as f:
            for j in range(0, int(sys.argv[1])):
                f.write(generate_record())
                f.write("\n")
        id_last = ID_START
    print("OK!")
