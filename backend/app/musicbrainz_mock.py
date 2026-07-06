"""Mock data for MusicBrainz API for testing and fallback."""

MOCK_DAFT_PUNK = {
    "id": "056e4f3e-d505-4dad-8ec1-d04f521cbb56",
    "type": "Group",
    "type-id": "e431f5f6-b5d2-343d-8b36-72607fffb74b",
    "name": "Daft Punk",
    "sort-name": "Daft Punk",
    "country": "FR",
    "area": {
        "id": "08310658-51eb-3801-80de-688bc51f2b99",
        "name": "France",
        "sort-name": "France",
        "type": "Country",
        "type-id": "06dd0ae4-8c74-30bb-b43d-95dcedf961de"
    },
    "disambiguation": "French electronic music duo",
    "life-span": {
        "begin": "1993-01-01",
        "end": "2021-02-22",
        "ended": True
    }
}

MOCK_BEYONCE = {
    "id": "6085a36e-4472-48de-8282-d2cfb65c4953",
    "type": "Person",
    "type-id": "b6e035f4-3ce9-331c-97d0-850397796d5b",
    "name": "Beyoncé",
    "sort-name": "Beyoncé",
    "country": "US",
    "disambiguation": "",
    "life-span": {
        "begin": "1981-09-04",
        "ended": False
    }
}

# Map MBID to artist detail
MOCK_ARTISTS_BY_MBID = {
    "056e4f3e-d505-4dad-8ec1-d04f521cbb56": MOCK_DAFT_PUNK,
    "6085a36e-4472-48de-8282-d2cfb65c4953": MOCK_BEYONCE,
}

MOCK_SEARCH_RESPONSES = {
    "daft punk": {
        "created": "2024-01-01T00:00:00.000Z",
        "count": 1,
        "offset": 0,
        "artists": [MOCK_DAFT_PUNK]
    },
    "beyonce": {
        "created": "2024-01-01T00:00:00.000Z",
        "count": 1,
        "offset": 0,
        "artists": [MOCK_BEYONCE]
    },
}


def get_mock_search(query: str):
    """Return mock search results for a given query."""
    key = query.lower().strip()
    if key in MOCK_SEARCH_RESPONSES:
        return MOCK_SEARCH_RESPONSES[key]
    # Default mock response for unknown queries
    return {
        "created": "2024-01-01T00:00:00.000Z",
        "count": 0,
        "offset": 0,
        "artists": []
    }


def get_mock_artist(mbid: str):
    """Return mock artist details for a given MBID."""
    if mbid in MOCK_ARTISTS_BY_MBID:
        return MOCK_ARTISTS_BY_MBID[mbid]
    # Return empty response for unknown MBID
    return {}
