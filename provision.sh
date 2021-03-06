export POSTGRES_DB_NAME="sampleapp"

set -x

export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8

sudo update-locale LANGUAGE=$LANGUAGE LC_ALL=$LC_ALL LANG=$LANG LC_TYPE=$LC_TYPE

cd
sudo apt-get update --yes
sudo apt-get install --yes \
  git \
  curl \
  wget \
  zlib1g-dev\
  build-essential\
  libssl-dev\
  libreadline-dev\
  libyaml-dev\
  libxml2-dev\
  libxslt1-dev\
  libcurl4-openssl-dev\
  python-software-properties \
  sqlite3 \
  libsqlite3-dev \
  2> /dev/null



echo "-----> install postgres"

sudo apt-get install --yes postgresql postgresql-contrib

sudo bash -c "cat > /etc/postgresql/9.5/main/pg_hba.conf" <<EOL
local all all trust
host all all 127.0.0.1/32 trust
host all all ::1/128 trust
EOL

sudo service postgresql restart



echo "-----> create postgres database"

createdb $POSTGRES_DB_NAME --username=postgres



echo "-----> install redis"

sudo apt-get install --yes redis-server
sudo systemctl enable redis-server.service
sudo systemctl restart redis-server.service



echo "-----> install elasticsearch"

sudo apt-get install --yes default-jre
cd
sudo curl --silent --show-error -O https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/deb/elasticsearch/2.3.1/elasticsearch-2.3.1.deb
sudo dpkg -i elasticsearch-2.3.1.deb
sudo systemctl enable elasticsearch.service

cd
sudo rm -rf ./elasticsearch*

echo "rewrite config"
sudo bash -c "cat > /etc/elasticsearch/elasticsearch.yml" <<EOL
index.number_of_shards: 1
index.number_of_replicas: 0
network.bind_host: 0
network.host: 0.0.0.0
script.inline: on
script.indexed: on
http.cors.enabled: true
http.cors.allow-origin: /https?:\/\/.*/
EOL

# TODO: Don't add the line if it's already there
sudo bash -c 'echo "ES_HEAP_SIZE=64m" >> /etc/default/elasticsearch'

sudo service elasticsearch start



echo "-----> install nodejs"

cd
sudo curl --silent --show-error -L https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install --yes nodejs



echo "-----> install yarn"

sudo curl --silent --show-error https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install --yes yarn



echo "-----> install ruby"

sudo apt-get install software-properties-common
sudo apt-add-repository ppa:brightbox/ruby-ng
sudo apt-get update --yes
sudo apt-get install --yes ruby2.4 ruby2.4-dev

cat >> ~/.bashrc <<EOL
export GEM_HOME=$HOME/.gem/ruby/2.4.0
export PATH=$HOME/.gem/ruby/2.4.0/bin:$PATH
EOL

source ~/.bashrc

sudo gem update --system
gem update
gem install bundle



echo "-----> update .gemrc"

cat > ~/.gemrc <<EOL
---
gem: --no-ri --no-rdoc
benchmark: false
verbose: true
backtrace: true
EOL



echo "-----> cleanup"

sudo apt autoremove --yes
sudo apt-get clean



echo "-----> report"

echo "ruby:          $(ruby --version)"
echo "gem:           $(gem --version) GEM_HOME: $GEM_HOME"
echo "bundler:       $(bundler --version)"
echo "yarn:          $(yarn --version)"
echo "node:          $(node --version)"
echo "psql:          $(psql --version)"
echo "redis:         $(redis-server --version)"
