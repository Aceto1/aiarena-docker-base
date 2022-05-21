# Sets up ai-arena client

FROM aiarena/sc2-linux-base:latest
MAINTAINER AI Arena <staff@aiarena.net>

# Create a symlink for the maps directory
# Remove the Maps that come with the SC2 client
RUN ln -s /root/StarCraftII/Maps /root/StarCraftII/maps \
    && rm -Rf /root/StarCraftII/maps/*

# Prevent caching unless client master branch changed
# https://codehunter.cc/a/git/how-to-prevent-dockerfile-caching-git-clone
ADD https://api.github.com/repos/aiarena/aiarena-client/git/refs/heads/master version.json

# Download python requirements files
ADD https://raw.githubusercontent.com/aiarena/aiarena-client/master/requirements.txt client-requirements.txt
ADD pyproject.toml pyproject.toml
ADD poetry.lock poetry.lock

# Merge client and bot requirements into pyproject.toml, generate a requirements.txt and install the packages globally
RUN pip install poetry \
    # Allows the final remove virtual env command
    && poetry config virtualenvs.in-project true \
    # Merge client requirements into current requirements
    && poetry add $(cat client-requirements.txt) \
    # Export unified requirements as requirements.txt
    && poetry export -f requirements.txt --output requirements.txt --without-hashes \
    # Install requirements.txt globally
    && pip install -r requirements.txt \
    # Remove virtual environment
    && rm -rf .venv

# Download the aiarena client
RUN git clone https://github.com/aiarena/aiarena-client.git aiarena-client

# Create bot users
RUN useradd -ms /bin/bash bot_player1 \
    && useradd -ms /bin/bash bot_player2 \
    # Create Bot and Replay directories
    && mkdir -p /root/aiarena-client/Bots \
    && mkdir -p /root/aiarena-client/Replays

# Change to working directory
WORKDIR /root/aiarena-client/

# Add Pythonpath to env
ENV PYTHONPATH=/root/aiarena-client/:/root/aiarena-client/arenaclient/
ENV HOST 0.0.0.0

# Install the arena client as a module
RUN python /root/aiarena-client/setup.py install

# Add Pythonpath to env
ENV PYTHONPATH=/root/aiarena-client/:/root/aiarena-client/arenaclient/

WORKDIR /root/aiarena-client/

# Run the match runner
ENTRYPOINT [ "timeout", "120m", "/usr/local/bin/python3.9", "-m", "arenaclient" ]
