require 'sinatra'
require 'json'
require 'rubygems'
require 'oauth'
require 'oauth/consumer'
require 'evernote'
require 'evernote_oauth'
require 'haml'

get '/test' do
    "fuck you"
end

get '/test2' do
    "<value>fuck Ass</value>"
end


get '/random' do
    #デベロッパートークン
    auth_token = "S=s1:U=91b5c:E=15877480ee1:C=1511f96df40:P=1cd:A=en-devtoken:V=2:H=dd73cdc1d04ff06afc122c887b0d81ed"

    #ノートのエンドポイントのURL
    note_store_url = "https://sandbox.evernote.com/shard/s1/notestore"

    note_store = Evernote::NoteStore.new(note_store_url)
    notebooks = note_store.listNotebooks(auth_token)
    default_notebook = notebooks[0]

    #検索条件を作る。
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

    #記事タイトル、URLをjsonで返す
    result = {
        title: title,
        url: url
    }
    result.to_json
end

use Rack::Session::Cookie,
  :key => "rack.session",
  :domain => "localhost",
  :path => "/",
  :expire_after => 3600,
  :secret => SecureRandom.hex(32)

get "/" do
  client = EvernoteOAuth::Client.new(
    :consumer_key => "susunshun",
    :consumer_secret => "830b44b89d85c7e4",
    :sandbox => true
  )
  callback_url = "#{request.url}callback"
  request_token = client.request_token(:oauth_callback => callback_url)
  session[:request_token] = request_token
  @authorize_url = request_token.authorize_url
  haml :index
end

get "/callback" do

  request_token = session[:request_token]
  verifier = params[:oauth_verifier]
  session[:access_token] = session[:request_token].get_access_token(:oauth_verifier => session[:oauth_verifier])
  @token = session[:access_token]

  haml :callback
end

__END__

@@ layout
!!!
%html(lang="ja")
  %head
    %meta(charset="UTF-8")
    %title #{@page_title}
  %body
    = yield

@@ index
- @page_title = "Authorize my app"
%p
  %a(href=@authorize_url)<Click to authorize my app

@@ callback
- @page_title = "Your token for Evernote access"
%p
  Your token is:
  %form
    %input(type="text" value=@token size=40)
