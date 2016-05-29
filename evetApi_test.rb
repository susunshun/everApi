##
# Copyright 2012 Evernote Corporation. All rights reserved.
##

require 'sinatra'
enable :sessions

# Load our dependencies and configuration settings
$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require "evernote_config.rb"

##
# Verify that you have obtained an Evernote API key
##
before do
  if OAUTH_CONSUMER_KEY.empty? || OAUTH_CONSUMER_SECRET.empty?
    halt '<span style="color:red">Before using this sample code you must edit evernote_config.rb and replace OAUTH_CONSUMER_KEY and OAUTH_CONSUMER_SECRET with the values that you received from Evernote. If you do not have an API key, you can request one from <a href="http://dev.evernote.com/documentation/cloud/">dev.evernote.com/documentation/cloud/</a>.</span>'
  end
end

helpers do
  def auth_token
    session[:access_token].token if session[:access_token]
  end

  def client
    @client ||= EvernoteOAuth::Client.new(token: auth_token, consumer_key:OAUTH_CONSUMER_KEY, consumer_secret:OAUTH_CONSUMER_SECRET, sandbox: SANDBOX)
  end

  def user_store
    @user_store ||= client.user_store
  end

  def note_store
    @note_store ||= client.note_store
  end

  def en_user
    user_store.getUser(auth_token)
  end

  def notebooks
    @notebooks ||= note_store.listNotebooks(auth_token)
  end

  def total_note_count
    filter = Evernote::EDAM::NoteStore::NoteFilter.new
    counts = note_store.findNoteCounts(auth_token, filter, false)
    notebooks.inject(0) do |total_count, notebook|
      total_count + (counts.notebookCounts[notebook.guid] || 0)
    end
  end
end

##
# Index page
##
get '/' do
  erb :index
end

##
# Reset the session
##
get '/reset' do
  session.clear
  redirect '/'
end

##
# Obtain temporary credentials
##
get '/requesttoken' do
  callback_url = request.url.chomp("requesttoken").concat("callback")
  begin
    session[:request_token] = client.request_token(:oauth_callback => callback_url)
    redirect '/authorize'
  rescue => e
    @last_error = "Error obtaining temporary credentials: #{e.message}"
    erb :error
  end
end

##
# Redirect the user to Evernote for authoriation
##
get '/authorize' do
  if session[:request_token]
    redirect session[:request_token].authorize_url
  else
    # You shouldn't be invoking this if you don't have a request token
    @last_error = "Request token not set."
    erb :error
  end
end

##
# Receive callback from the Evernote authorization page
##
get '/callback' do
  unless params['oauth_verifier'] || session['request_token']
    @last_error = "Content owner did not authorize the temporary credentials"
    halt erb :error
  end
  session[:oauth_verifier] = params['oauth_verifier']
  begin
    session[:access_token] = session[:request_token].get_access_token(:oauth_verifier => session[:oauth_verifier])
    redirect '/list'
  rescue => e
    @last_error = 'Error extracting access token'
    erb :error
  end
end


##
# Access the user's Evernote account and display account data
##
get '/list' do
  begin
    # Get notebooks
    session[:notebooks] = notebooks.map(&:name)
    # Get username
    session[:username] = en_user.username
    # Get total note count
    session[:total_notes] = total_note_count
    erb :index
  rescue => e
    @last_error = "Error listing notebooks: #{e.message}"
    erb :error
  end
end

get '/random' do
    #デベロッパートークン
    auth_token = "S=s1:U=91b5c:E=15877480ee1:C=1511f96df40:P=1cd:A=en-devtoken:V=2:H=dd73cdc1d04ff06afc122c887b0d81ed"

    #ノートのエンドポイントのURL
    note_store_url = "https://sandbox.evernote.com/shard/s1/notestore"
    #note_store_url = "http://sandbox.evernote.com/edam/note/s1"

    note_store = Evernote::NoteStore.new(note_store_url)
    notebooks = note_store.listNotebooks(auth_token)
    default_notebook = notebooks[0]

#    notebooks.each {|n| puts [n.name].inspect}

    ##検索条件を作る。
    filter = Evernote::EDAM::NoteStore::NoteFilter.new
    #デフォルトノートブック中のノート一覧を探す。
    #ノートブックのIDを取得し検索条件に入れる。
    filter.notebookGuid = default_notebook.guid
    #取得する最大数を設定
    limit = 1000
    #何件目から取得するか
    offset  =0
    note_list = note_store.findNotes auth_token, filter, offset, limit
#    puts "notesizeは"+note_list.notes.length.to_s
    note_index = rand(note_list.notes.length)
    #表示してみる
    title = note_list.notes[note_index].title
    url = note_list.notes[note_index].attributes.sourceURL

#    note_list.notes.each do |e|
#        puts [e.title,e.created,e.content,e.attributes.sourceURL].inspect #ノートのタイトルやメタデータは取れるよ。でも中身はないよ！
#        title = e.title
#        url = e.attributes.sourceURL
#        #puts note_list.notes.last.attributes.sourceURL
#    end

    #記事タイトル、URLをjsonで返す
    result = {
        title: title,
        url: url
    }
    result.to_json
end

__END__

@@ index
<html>
<head>
  <title>Evernote Ruby Example App</title>
</head>
<body>
  <a href="/requesttoken">Click here</a> to authenticate this application using OAuth.
  <% if session[:notebooks] %>
  <hr />
  <h3>The current user is <%= session[:username] %> and there are <%= session[:total_notes] %> notes in their account</h3>
  <br />
  <h3>Here are the notebooks in this account:</h3>
  <ul>
    <% session[:notebooks].each do |notebook| %>
    <li><%= notebook %></li>
    <% end %>
  </ul>
  <% end %>
</body>
</html>

@@ error
<html>
<head>
  <title>Evernote Ruby Example App &mdash; Error</title>
</head>
<body>
  <p>An error occurred: <%= @last_error %></p>
  <p>Please <a href="/reset">start over</a>.</p>
</body>
</html>
