# Survival Analysis Tool

Application structure:

```
├── backend
│   ├── __init__.py
│   ├── app.py
│   ├── can-sat.wsgi
│   ├── data
│   ├── requirements.txt
│   ├── scripts
│   └── src
└── frontend
    ├── README.md
    ├── build
    ├── craco.config.js
    ├── node_modules
    ├── package-lock.json
    ├── package.json
    ├── public
    ├── src
    ├── tailwind.config.js
    └── tsconfig.json
```

In brief:

- `backend`: contains the server backend code and analysis code (written in Python). 
    - `data` contains a `data.db` file which contains IDs of valid studies with pre-fetched clinical data and outcome data. Studies with incomplete or insufficient data are excluded from this file.
    - `scripts`: contains the `generate_db.py` script to generate the `data.db` file. There is also a `generate_db.log` file which lists the studies included and excluded after running the script. 
    - `src`: contains the actual backend source and analysis code. 
        - `analysis.py`: code which performs the data processing and survival analsis (based on the lifelines package).
        - `cbioportal.py`: code to interface with the public cBioPortal API. 
        - `test_analysis.py` and `test_cbioportal.py`: unit tests for each of the above files.
- `frontend`: contains the frontend client code (written in TypeScript). 
    - `build`: the actual client app built from the source. 
    - `src`: contains all the source code files for the client
        - `resources`: mostly images for the how-to page
        - Component .tsx files 
