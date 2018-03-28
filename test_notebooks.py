import os
import subprocess
import pytest


run = os.environ.get("TEST_RUN", "false").lower() == "true"
timeout = int(os.environ.get("TEST_TIMOUT", 120))


@pytest.mark.parametrize('notebook', [
    'README.ipynb',
    pytest.mark.xfail(run=run, reason='Takes too long to run')(
        'notebooks/CalculateSharpness.ipynb'),
    pytest.mark.xfail(run=run, reason='Requires R')(
        'notebooks/CondensationBulkAnnotations.R.ipynb'),
    pytest.mark.xfail(run=run, reason='Requires web')(
        'notebooks/CreateOmeroFigures.ipynb'),
    pytest.mark.xfail(run=run, reason=(
        'bokeh.charts replaced by bkcharts. '
        'bkcharts is unmaintained and broken '
        'https://stackoverflow.com/a/46287065'))(
        'notebooks/Figure_1_Sampling_of_Phenotypes.ipynb'),
    'notebooks/GeneNetwork.ipynb',
    'notebooks/GenesToPhenotypes.ipynb',
    'notebooks/Getting_Started.ipynb',
    'notebooks/IDR_API_example_script.ipynb',
    pytest.mark.xfail(run=run, reason='Intermittent failures')(
        'notebooks/PCAanalysisOfCharmFeatures.ipynb'),
    pytest.mark.xfail(run=run, reason='New notebook, not yet supported')(
        'notebooks/QueryIDRWithGeneLists.ipynb'),
    pytest.mark.xfail(run=run, reason='Intermittent failures')(
        'notebooks/RohnPhenotypeClustering.ipynb'),
    'notebooks/SysgroOverview.ipynb',
    pytest.mark.xfail(run=run, reason='Broken')(
        'notebooks/SysgroRoiLength.ipynb'),
    'notebooks/Using_Jupyter.ipynb',
])
def test_notebook(notebook):
    subprocess.check_call([
        'jupyter',
        'nbconvert',
        '--execute',
        '--stdout',
        '--ExecutePreprocessor.timeout=%s' % timeout,
        os.path.join('/notebooks', notebook),
    ])
