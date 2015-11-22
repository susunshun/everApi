require 'sinatra'
require 'json'
require 'rubygems'
require 'evernote'

# set :bind, '0.0.0.0'

get '/' do
        "<h1>Wooooooooooooo!<h1>"
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
