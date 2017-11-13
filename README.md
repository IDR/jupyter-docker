# Jupyter Docker

This is a Jupyter notebook Docker image for running https://github.com/IDR/idr-notebooks/

To run this as a standalone image:

    docker run --rm -p 8888:8888 -e IDR_HOST=<host> -e IDR_USER=<user> -e IDR_PASSWORD=<password> imagedata/jupyter-docker

And open the displayed URL in your web browser


## Tests

To check that most notebooks can be executed:

    IDR_HOST=<host> -e IDR_USER=<user> -e IDR_PASSWORD=<password> ./test.sh

This will exclude notebooks that take a long time to execute or require manual input; you should test these manually in the Jupyter notebook web interface.
See the `pytest.mark.xfail` markers in [test_notebooks.py](test_notebooks.py) for details.
