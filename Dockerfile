FROM ubuntu:24.10

RUN apt-get update \
	&& apt-get install --no-install-recommends -y software-properties-common=0.102 \
	&& add-apt-repository ppa:zhangsongcui3371/fastfetch \
	&& apt-get update \
	&& apt-get install --no-install-recommends -y \
	gcc=4:14.1.0-2ubuntu1 \
	g++=4:14.1.0-2ubuntu1 \
	git=1:2.45.2-1ubuntu1 \
	ca-certificates=20240203 \
	neovim=0.9.5-7 \
	nodejs=20.16.0+dfsg-1ubuntu1 \
	pipx=1.6.0-1 \
	curl=8.9.1-2ubuntu2 \
	npm=9.2.0~ds1-3 \
	unzip=6.0-28ubuntu6 \
	ranger=1.9.3-5 \
	cmake=3.30.3-1 \
	make=4.3-4.1build2 \
	pkg-config=1.8.1-3ubuntu1 \
	bat=0.24.0-1build2 \
	fzf=0.46.1-1 \
	eza=0.19.2-2 \
	ncdu=1.19-0.1 \
	feh=3.10.2-1 \
	ripgrep=14.1.0-2 \
	fd-find=10.2.0-1 \
	fastfetch=2.28.0 \
	apt-file=3.3 \
	wireguard-tools=1.0.20210914-1.1ubuntu1 \
	rsync=3.3.0-1 \
	tmux=3.4-7 \
	opendoas=6.8.2-1 \
	cargo=1.80.1ubuntu2 \
	golang-go=2:1.23~1

# More user friendly aliases
RUN ln -s "$(command -v fdfind)" /usr/bin/fd \
	&& ln -s "$(command -v doas)" /usr/bin/sudo

RUN git clone https://github.com/jstkdng/ueberzugpp.git -b v2.9.6 --depth 1 /usr/local/src/ueberzugpp \
	&& apt-get install --no-install-recommends -y \
	libtbb-dev=2021.12.0-1ubuntu2 \
	libxcb-image0-dev=0.4.0-2build1 \
	libxcb-res0-dev=1.17.0-2 \
	libvips-dev=8.15.2-2 \
	libsixel-dev=1.10.3-3build1 \
	libchafa-dev=1.14.0-1.1build1
RUN cmake -D CMAKE_BUILD_TYPE=Release -D ENABLE_OPENCV=OFF -S /usr/local/src/ueberzugpp/ -B /usr/local/src/ueberzugpp/build \
	&& cmake --build /usr/local/src/ueberzugpp/build -j "$(nproc)" \
	&& mv -v /usr/local/src/ueberzugpp/build/ueberzug /usr/local/bin/ueberzug \
	&& rm -rv /usr/local/src/ueberzugpp

RUN git clone --depth=1 -b v0.44.1 https://github.com/jesseduffield/lazygit.git /usr/local/src/lazygit
WORKDIR /usr/local/src/lazygit
RUN go install -buildvcs=false \
	&& mv -v /root/go/bin/lazygit /usr/local/bin/lazygit \
	&& rm -rv /usr/local/src/lazygit

RUN git clone --depth=1 -b v0.23.3 https://github.com/jesseduffield/lazydocker.git /usr/local/src/lazydocker
WORKDIR /usr/local/src/lazydocker
RUN go install -buildvcs=false \
	&& mv -v /root/go/bin/lazydocker /usr/local/bin/lazydocker \
	&& rm -rv /usr/local/src/lazydocker

RUN git clone --depth=1 -b v0.1.4 https://github.com/jesseduffield/lazynpm.git /usr/local/src/lazynpm
WORKDIR /usr/local/src/lazynpm
RUN go install -buildvcs=false \
	&& mv -v /root/go/bin/lazynpm /usr/local/bin/lazynpm \
	&& rm -rv /usr/local/src/lazynpm

RUN cargo install --locked difftastic@0.61.0 \
	&& mv -v /root/.cargo/bin/difft /usr/local/bin/difft

RUN apt-get remove -y golang-go cargo \
	&& apt-get autoremove -y \
	&& apt-get autoclean -y \
	&& rm -rv /var/lib/apt/lists/* \
	&& rm -rv /root/go \
	&& rm -rv /root/.cargo \
	&& useradd -m saundersp \
	&& rm -v "$(command -v vi)"

USER saundersp

RUN bash -i -c 'pipx install dooit==2.2.0'

# Copying local repository
#WORKDIR /home/saundersp/dotfiles
#COPY . .

# Cloning remote repository
WORKDIR /home/saundersp
RUN git clone --depth=1 https://github.com/saundersp/dotfiles.git
WORKDIR /home/saundersp/dotfiles

RUN ./auto.sh s

ENTRYPOINT ["bash"]
