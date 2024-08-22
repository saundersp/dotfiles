FROM ubuntu:24.04

RUN apt-get update \
	&& apt-get install --no-install-recommends -y software-properties-common=0.99.48 \
	&& add-apt-repository ppa:zhangsongcui3371/fastfetch \
	&& apt-get update \
	&& apt-get install --no-install-recommends -y \
	gcc=4:13.2.0-7ubuntu1 \
	g++=4:13.2.0-7ubuntu1 \
	git=1:2.43.0-1ubuntu7 \
	ca-certificates=20240203 \
	neovim=0.9.5-6ubuntu2 \
	nodejs=18.19.1+dfsg-6ubuntu5 \
	pipx=1.4.3-1 \
	curl=8.5.0-2ubuntu10.3 \
	npm=9.2.0~ds1-2 \
	unzip=6.0-28ubuntu4 \
	ranger=1.9.3-5 \
	cmake=3.28.3-1build7 \
	make=4.3-4.1build2 \
	pkg-config=1.8.1-2build1 \
	bat=0.24.0-1build1 \
	fzf=0.44.1-1 \
	eza=0.18.2-1 \
	ncdu=1.19-0.1 \
	feh=3.10.1-1build3 \
	ripgrep=14.1.0-1 \
	fd-find=9.0.0-1 \
	fastfetch=2.21.3 \
	apt-file=3.3 \
	wireguard-tools=1.0.20210914-1ubuntu4 \
	rsync=3.2.7-1ubuntu1 \
	tmux=3.4-1build1 \
	opendoas=6.8.2-1 \
	cargo=1.75.0+dfsg0ubuntu1-0ubuntu7.1 \
	golang-go=2:1.22~2build1

# More user friendly aliases
RUN ln -s "$(command -v fdfind)" /usr/bin/fd \
	&& ln -s "$(command -v doas)" /usr/bin/sudo

RUN git clone https://github.com/jstkdng/ueberzugpp.git -b v2.9.6 --depth 1 /usr/local/src/ueberzugpp \
	&& apt-get install --no-install-recommends -y libtbb-dev=2021.11.0-2ubuntu2 \
	libxcb-util-dev=0.4.0-1build3 \
	libxcb-image0-dev=0.4.0-2build1 \
	libxcb-res0-dev=1.15-1ubuntu2 \
	libvips-dev=8.15.1-1.1build4 \
	libsixel-dev=1.10.3-3build1 \
	libchafa-dev=1.14.0-1.1build1 \
	&& cmake -D CMAKE_BUILD_TYPE=Release -D ENABLE_OPENCV=OFF -S /usr/local/src/ueberzugpp/ -B /usr/local/src/ueberzugpp/build \
	&& cmake --build /usr/local/src/ueberzugpp/build -j "$(nproc)" \
	&& mv -v /usr/local/src/ueberzugpp/build/ueberzug /usr/local/bin/ueberzug \
	&& rm -rv /usr/local/src/ueberzugpp

RUN git clone --depth=1 -b v0.43.1 https://github.com/jesseduffield/lazygit.git /usr/local/src/lazygit
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

RUN cargo install --locked difftastic@0.58.0 \
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
