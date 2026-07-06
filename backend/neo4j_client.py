import os
from neo4j import GraphDatabase
from typing import Optional
from dotenv import load_dotenv

load_dotenv()

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "neo4j")

_driver: Optional[GraphDatabase.driver] = None


def get_driver():
    global _driver
    if _driver is None:
        _driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))
    return _driver


def close_driver():
    global _driver
    if _driver is not None:
        _driver.close()
        _driver = None


def create_or_update_artist(mbid: str, name: str, country: Optional[str] = None, type_: Optional[str] = None, begin_date: Optional[str] = None, disambiguation: Optional[str] = None):
    drv = get_driver()
    query = (
        "MERGE (a:Artist {mbid: $mbid})\n"
        "SET a.name = $name, a.country = $country, a.type = $type, a.beginDate = $beginDate, a.disambiguation = $disambiguation\n"
        "RETURN a"
    )
    with drv.session() as session:
        result = session.run(query, mbid=mbid, name=name, country=country, type=type_, beginDate=begin_date, disambiguation=disambiguation)
        return result.single()
