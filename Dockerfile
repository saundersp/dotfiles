FROM ubuntu:25.04

RUN apt-get update \
	&& apt-get install --no-install-recommends -y \
	gcc=4:14.1.0-2ubuntu1 \
	g++=4:14.1.0-2ubuntu1 \
	git-svn=1:2.47.1-0ubuntu1 \
	ca-certificates=20240203 \
	neovim=0.9.5-10 \
	nodejs=20.18.1+dfsg-1ubuntu1 \
	pipx=1.7.1-1 \
	curl=8.11.1-1ubuntu1 \
	npm=9.2.0~ds1-3 \
	unzip=6.0-28ubuntu6 \
	ranger=1.9.4-1 \
	cmake=3.31.2-1 \
	make=4.4.1-1 \
	pkgconf=1.8.1-4 \
	bat=0.24.0-1build2 \
	fzf=0.57.0-1 \
	eza=0.19.2-2 \
	ncdu=1.21-1 \
	feh=3.10.3-1 \
	ripgrep=14.1.1-1 \
	fd-find=10.2.0-1 \
	fastfetch=2.30.1+dfsg-1 \
	apt-file=3.3 \
	wireguard-tools=1.0.20210914-1.1ubuntu1 \
	rsync=3.3.0+ds1-2 \
	tmux=3.4-7 \
	opendoas=6.8.2-1 \
	cargo=1.80.1ubuntu2 \
	golang-go=2:1.23~2

# More user friendly aliases
RUN ln -s "$(command -v fdfind)" /usr/bin/fd \
	&& ln -s "$(command -v doas)" /usr/bin/sudo

RUN git clone https://github.com/jstkdng/ueberzugpp.git -b v2.9.6 --depth 1 /usr/local/src/ueberzugpp \
	&& apt-get install --no-install-recommends -y \
	libtbb-dev=2021.12.0-1ubuntu2 \
	libxcb-image0-dev=0.4.0-2build1 \
	libxcb-res0-dev=1.17.0-2 \
	libvips-dev=8.16.0-2 \
	libsixel-dev=1.10.3-3build1 \
	libchafa-dev=1.14.5-1
RUN cmake -D CMAKE_BUILD_TYPE=Release -D ENABLE_OPENCV=OFF -S /usr/local/src/ueberzugpp/ -B /usr/local/src/ueberzugpp/build \
	&& cmake --build /usr/local/src/ueberzugpp/build -j "$(nproc)" \
	&& mv -v /usr/local/src/ueberzugpp/build/ueberzug /usr/local/bin/ueberzug \
	&& rm -r /usr/local/src/ueberzugpp

RUN git clone --depth=1 -b v0.44.1 https://github.com/jesseduffield/lazygit.git /usr/local/src/lazygit
WORKDIR /usr/local/src/lazygit
RUN go install -buildvcs=false \
	&& mv -v /root/go/bin/lazygit /usr/local/bin/lazygit \
	&& rm -r /usr/local/src/lazygit

RUN git clone --depth=1 -b v0.24.1 https://github.com/jesseduffield/lazydocker.git /usr/local/src/lazydocker
WORKDIR /usr/local/src/lazydocker
RUN go install -buildvcs=false \
	&& mv -v /root/go/bin/lazydocker /usr/local/bin/lazydocker \
	&& rm -r /usr/local/src/lazydocker

RUN git clone --depth=1 -b v0.1.4 https://github.com/jesseduffield/lazynpm.git /usr/local/src/lazynpm
WORKDIR /usr/local/src/lazynpm
RUN go install -buildvcs=false \
	&& mv -v /root/go/bin/lazynpm /usr/local/bin/lazynpm \
	&& rm -r /usr/local/src/lazynpm

RUN cargo install --locked difftastic@0.61.0 \
	&& mv -v /root/.cargo/bin/difft /usr/local/bin/difft

RUN apt-get remove -y golang-go cargo \
	&& apt-get autoremove -y \
	&& apt-get autoclean -y \
	&& rm -r /var/lib/apt/lists/* \
	&& rm -r /root/go \
	&& rm -r /root/.cargo \
	&& useradd -m saundersp \
	&& rm -v "$(command -v vi)"

USER saundersp

RUN bash -i -c 'pipx install dooit==3.1.0'

WORKDIR /home/saundersp
# Copying local repository
#COPY . .
# Cloning remote repository
RUN git clone --depth=1 https://github.com/saundersp/dotfiles.git

WORKDIR /home/saundersp/dotfiles

RUN ./auto.sh s

ENTRYPOINT ["bash"]
