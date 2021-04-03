#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -f "$DIR"/config ] ; then
    source "$DIR"/config
fi

mkdir -p posts db
POSTS="$DIR/posts"

db="$DIR/db/db.tsv"
linkdb="$DIR/db/linkdb.tsv"
tagdb="$DIR/db/tagdb.tsv"
touch $db $linkdb $tagdb

gen () {
    # Accept font from folder (if any)
    fontfile=$(find . -maxdepth 1 -name "*.ttf" | grep -vi "bold\|italic"| awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2- | sed 's/^.*\///')
    fontfamily=$(echo "$fontfile" | sed 's/\.ttf$//')
    if [ ! -z "$fontfamily" ] ; then
        font="@font-face {
    font-family: '$fontfamily, monospace';
        src: url('$fontfile') format('truetype');
    font-weight: normal;
        font-style: normal;
    }
    "
    else
        fontfamily="monospace"
    fi

    echo "Start..."
    # Making database

# Creating webpage


read -r -d '' WEBSITEHEAD <<EOF
        <head>
                <meta http-equiv="content-type" content="text/html; charset=utf-8">
                <meta name="author" content="$usually_author">
                <meta name="copyright" content="I don't give a heck.">
                <title>$site_title</title>
                <style>
$font
body { background: #f3f3f3; font-family: '$fontfamily', monospace; width: 50%; }
pre { font-family: '$fontfamily', monospace;  margin: 0px; padding: 0px; }
.content a {
    color: #000;
    text-decoration: none;
    background-image: linear-gradient(120deg, #e96443 0%, #904e95 100%);
    background-repeat: no-repeat;
    background-size: 0 0;
    background-position: 100% 21%;
    /* transition: 0.15s ease-out; */
}
.content a::after {
    position: relative;
    /* content: "\FEFF°"; */
    margin-left: 0.10em;
    font-size: 90%;
    top: -0.10em;
    color: #BD596C;
    font-feature-settings: "caps";
    font-variant-numeric: normal;
}
.content a:hover {
    background-size: 100% 100%;
    color: #fff;
}
.content a:hover::after {
    color: #904e95;
}
a:link { text-decoration: none; color: blue }
a:visited { text-decoration: none; color: blue }
a:hover { text-decoration: none; color: deepskyblue }
p { font-family: '$fontfamily', monospace; }
img { width: 200px; }
.content table {
  display: block;
  width: 100%;
  overflow: auto;
}

.content table th {
  font-weight: 600;
}

.content table td,
.content table th {
  padding: 6px 13px;
  border: 1px solid #dfe2e5;
}

.content table tr {
  background-color: #fff;
  border-top: 1px solid #c6cbd1;
}

.content table tr:nth-child(2n) {
  background-color: #f6f8fa;
}

                </style>
        </head>
        <body><blockquote>
<pre><a href="index.html">-\`._- \`._- \`._- \`._- \`._- \`._- \`._- \`._- \`._- \`._- \`._- \`._-</a><font color="red"><strong>
$(figlet -f "$figlet_font" "$site_name")</strong></font></pre>
<a href="links.html">Links from posts</a> | <a href="tags.html">Tags</a> | <a href="toc.html">TOC</a> | <a href="contact.html">Contact</a>
<br>
<font color="blue">---------------------------------------</font>
<div class="content">
<!-- CUT HERE -->
EOF

read -r -d '' WEBSITETAIL <<EOF
</div><pre><a href="index.html">-\`._- \`._- \`._- \`._- \`._- \`._- \`._- \`._- \`._- \`._- \`._- \`._-</a>
                              <font color="red">$mail</font></pre>
</blockquote></body>

</html>

EOF
echo "$WEBSITEHEAD" > "$DIR"/index.html



# Adding posts
    sort -rnk1 -o "$db" "$db"
    sort -t$'\t' -rk7,7 -o "$db" "$db"
    awk -F'\t' '{print $3}' "$db" >> "$DIR"/index.html
echo "$WEBSITETAIL" >> "$DIR"/index.html
sed -i 's/\\n/\n/g' "$DIR"/index.html

# Adding tags (deprecated)
#taglist=$(awk -F'\t' '{print $NF}' "$db" | sed '/^$/d'  | tr ' ' '\n' | sort -u | tr '\n' ' ' | sed 's/ $/\n/' | fold -w 80 -s | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g')
#sed -i "/CUT HERE/a <font color=\"blue\">---------------------------------</font>\n" "$DIR"/index.html
#sed -i "/CUT HERE/a $taglist" "$DIR"/index.html
#sed -i "/CUT HERE/a Tags: <em>use Ctrl-F or <a href=\"tags.html\">check tag page</a></em>" "$DIR"/index.html

# Adding tagpage
taglist=$(awk -F'\t' '{print $4}' "$db"  | sed '/^$/d'  | tr ' ' '\n' | sort -u)
echo "$WEBSITEHEAD" > "$DIR"/tags.html

tagspage=$(while read -r line ; do
    echo -e "\n   <b>$line</b>"
    while IFS= read -r tag ; do
        link="$(echo "$line"  | grep -o 'id="[[:digit:]]*-[[:digit:]]*-[[:digit:]]*_[[:digit:]]*:[[:digit:]]*.M' | sed 's/id..//')"
        title="$(echo "$tag" | awk -F'\t' '{print $6}')"
        echo "<a href=\"index.html#$link\">$title</a>"
    done <<< $(grep "$line[[:space:]]" "$db")
done <<< "$taglist" | fold -w 62 -s | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' | sed 's/"/\\"/g' | sed 's/^/\\\n/')
sed -i "/CUT HERE/a $tagspage" "$DIR"/tags.html
taglist=$(echo "$taglist" | tr '\n' ' ' | sed 's/ $/\n/' | fold -w 62 -s | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g')
sed -i "/CUT HERE/a <font color=\"blue\">---------------------------------</font>" "$DIR"/tags.html
sed -i "/CUT HERE/a <em>Tags:</em> $taglist" "$DIR"/tags.html
sed -i "/CUT HERE/a <a href=\"index.html\">Back to index</a>\n" "$DIR"/tags.html
sed -i "/CUT HERE/a <pre>" "$DIR"/tags.html
echo "</pre>" >> "$DIR"/tags.html
echo "$WEBSITETAIL" >> "$DIR"/tags.html

# Adding linkpage
echo "$WEBSITEHEAD" > "$DIR"/links.html
while IFS= read -r line ; do
    title="$(echo "$line" | awk -F'\t' '{print $6}')"
    post="$(echo "$line"  | grep -o 'id="[[:digit:]]*-[[:digit:]]*-[[:digit:]]*_[[:digit:]]*:[[:digit:]]*.M' | sed 's/id..//')"
    tags="$(echo "$line" | awk -F'\t' '{print $4}')"
    links=$(echo "$line" | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | sort -u | grep -v "\.png$\|\.jpg$\|\.mp4\|\.mp3")
    if [ -z "$links" ] ; then
        continue
    fi
    while IFS= read -r link ; do
        if grep -q -P "^$link\t" "$linkdb" ; then
            linktitle=$(grep -P "^$link\t" "$linkdb" | awk -F'\t' '{print $2}')
            string="$string\n$link - <em><font color=\"grey\">$linktitle</font></em>"
        else
            linktitle=$(wget -qO- "$link" | awk -v IGNORECASE=1 -v RS='</title' 'RT{gsub(/.*<title[^>]*>/,"");print;exit}')
            string="$string\n$link - <em><font color=\"grey\">$linktitle</font></em>"
            echo -e "$link\t$linktitle" >> "$linkdb"
        fi
    done <<< "$links"
    sed -i "/CUT HERE/a <pre>\n\n   <b><a href=\"index.html#$post\">$title</a></b> <font color=\"gray\">$tags</font>$string</pre>" "$DIR"/links.html
    unset string
done <<< "$(awk -F'\t' '$5 == "yes"' $db | tac)"
sed -i "/CUT HERE/a <a href=\"index.html\">Back to index</a>" "$DIR"/links.html
echo "$WEBSITETAIL" >> "$DIR"/links.html

echo "$WEBSITEHEAD $WEBSITETAIL" > "$DIR"/toc.html
echo "$WEBSITEHEAD" > "$DIR"/contact.html
echo "github: <a href=\"https://github.com/asakura42\">https://github.com/asakura42</a>
<br><br>
monero: 42CyxfVhXjiNNxmYfShh5gSCT9XwZmh7WZh3shP72qz5YkrX1EMYR733evdRhYt9VM55MkrwJd9awS1mTxg8U8Q1VDWjFyW" >> "$DIR"/contact.html
echo "$WEBSITETAIL" >> "$DIR"/contact.html
echo "Done"

if [[ "$neocities" == "yes" && "$1" == "-n" ]] ; then
    neouser=$(pass find neocities | tail -n1 | awk '{print $NF}')
    neologin=$(echo "$neouser" | sed 's/_neocities//')
    cd "$DIR"
    files="$(echo -e "$(find . -maxdepth 1 -name "*.html" |
        sed 's/^.\///')\n$(find . -maxdepth 1 -name "*.ttf" | awk '{print length($1), $1}' | sort -nk 1 | head -1 | awk '{print $2}' | sed 's/^.\///')")"
    echo "$files"
    echo "Upload these files? [y/n]"
    read confirm
    if [[ "$confirm" == "y" ]] ; then
        while IFS= read -r line ; do
            curl -F "$line=@$line" "https://$neologin:$(pass show $neouser)@neocities.org/api/upload"
        done <<< "$files"
    fi
fi

if [[ "$1" == "-g" ]] ; then
    git commit . -m "Updated"
    git push
fi

}

edit () {
    echo "$1 $2 $3 $4"
    if [ ! -z "$1" ] ; then
        article="$1"
    fi

    if [ -z "$article" ] ; then
        echo "Name your article:"
        read article
    fi
    name="$(echo "$article" | sed 's/^.*\///;s/\.md//g;s/ /_/g')"
    if [ -f "$POSTS/$name".md ] ; then
        $EDITOR "$POSTS/$name".md
    else
        echo -e "# $article\n$(date "+%Y-%m-%d %I:%M%p")\n$usually_author\n\n\n\n\n#tag" > "$POSTS/$name".md
        $EDITOR "$POSTS"/"$name".md
    fi
    sed -i '/^$/N;/^\n$/D' "$POSTS"/"$name".md

    if [ -z "$(sed '4q;d' "$POSTS"/"$name".md)" ] && date -d "$(sed '2q;d' "$POSTS"/"$name".md)" &> /dev/null ; then
        title=$(sed 's/^# //;1q;d' "$POSTS"/"$name".md)
        date=$(date --date="$(sed '2q;d' "$POSTS"/"$name".md)" +"%s")
        humandatetime=$(sed '2q;d' "$POSTS"/"$name".md)
        datelink=$(echo "$humandatetime" | sed 's/ /_/g')
        author=$(sed '3q;d' "$POSTS"/"$name".md)
        taglist=$(tail -n1 "$POSTS"/"$name".md | grep -o '#[a-zA-Z0-9]*' | grep -v "^#$" | tr '\n' ' ' | sed 's/ $/\n/' )
        base="$name.md"
        pinned="$(echo "$title" | grep -o "📌")"
        post=$(sed '1,4d;${/^#/d;};${/^$/d;}' "$POSTS"/"$name".md | lowdown | awk '{printf "%s\\\\n", $0}')
        echo "$post" | grep -q -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" && links="yes"
        sed -i "/\t$base\t/d" "$db"
        echo -e "$date\t$base\t<p><span id=\"$datelink\"></span><pre>$humandatetime - <font size=\"+1\"><b>$title</b></font> <font color=\"grey\">by $author</font> <a href=\"#$datelink\">#</a> <font color=\"grey\"><span title=\"filename: $base\\\nlast modified: $(stat -c '%y' "$POSTS"/"$name".md | sed 's/\..*//')\">?</span></font></pre></p>\\\n$post<p><font color=\"LightSlateGray\">$taglist</font></p><font color=\"DarkSlateGrey\">^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^</font>\t$taglist\t$links\t$title\t$pinned" >> "$db"
    fi
}

if [ ! -f "$DIR"/config ] ; then
    echo "You need to edit config."
    echo "Enter preferred figlet font (e.g. standard)"
    read figlet_font
    echo "Enter site name"
    read site_name
    echo "Enter html title"
    read site_title
    echo "Enter admin mail"
    read mail
    echo "Enter author name"
    read usually_author
    echo -e "figlet_font=\"$figlet_font\"\nsite_name=\"$site_name\"\nsite_title=\"$site_title\"\nmail=\"$mail\"\nusually_author=\"$usually_author\"" > "$DIR"/config
    echo
    echo "Now rerun script."
    exit
fi

if [[ "$1" == "-e" ]] ; then
    edit "$2"
elif [[ "$1" == "-g" ]] ; then
    gen "$2"
else
    echo -e "Usage:\n$basename -e - write post\n$basename -g - generate index.html\n$basename -g -n - generate index.html and upload to neocities"
fi


