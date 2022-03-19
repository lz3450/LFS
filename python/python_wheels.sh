PIP="python3 -m pip"
WHEEL_ARGS="wheel -w ~/wheels --no-binary :all:"
INSTALL_ARGS="install -U -f ~/wheels"

${PIP} ${WHEEL_ARGS} pip
sudo ${PIP} ${INSTALL_ARGS} pip

${PIP} ${WHEEL_ARGS} setuptools
sudo ${PIP} ${INSTALL_ARGS} setuptools

${PIP} ${WHEEL_ARGS} wheel
sudo ${PIP} ${INSTALL_ARGS} wheel

${PIP} ${WHEEL_ARGS} autopep8 pylint
sudo ${PIP} ${INSTALL_ARGS} autopep8 pylint

${PIP} ${WHEEL_ARGS} numpy pandas ipython jupyter
sudo ${PIP} ${INSTALL_ARGS} numpy pandas ipython jupyter
