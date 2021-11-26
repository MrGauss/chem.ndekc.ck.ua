<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )        { require( CLASSES_DIR.DS.'trait.basic.php' ); }

class tags
{
    use basic;

    public static final function hash_tags_2_urls_html( $text, $mod = false )
    {
        $mod = common::filter( $mod ? $mod : _MOD_ );

        $text_original = $text;

        $text = common::stripslashes( $text );
        $text = common::html_entity_decode( $text );

        $tags = array();
        while( preg_match( '!\#(\S{3,})!i', $text, $founded_tag ) )
        {
            if( is_array($founded_tag) && isset($founded_tag[0]) ){ $founded_tag = $founded_tag[0]; }else{ exit; }

            $tag_md5 = md5($founded_tag);

            $text = str_replace( $founded_tag, $tag_md5, $text );

            $tags[$tag_md5] = $founded_tag;
        }

        if( !count($tags) ){ return $text_original; }

        $text = common::db2html( $text );

        foreach( $tags as $md5 => $tag )
        {
            $text = str_replace( $md5, '<a class="hashtag" href="'.HOMEURL.HOME_INDEX.'?mod='.$mod.'&search_tag='.urlencode($tag).'">'.common::db2html( $tag ).'</a>', $text );
        }

        return $text;
    }

}