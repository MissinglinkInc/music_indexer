<?php

class Songs_Model extends CI_Model {

	public function __construct(){
		parent::__construct();
		$this->load->database('default');
	}

	public function ngram_search($query_ngram,$search_by) {
		echo $query_ngram;
		$by = '';
		foreach ($search_by as $name) {
			$by .= 'ngram_'.$name.',';
		}
		$by = rtrim($by,',');
		$sql = "select title,artist,album,year,subtitle,time,path from songs where match( {$by} ) against( ? in boolean mode );";
		$res = $this->db->query($sql,array($query_ngram));
		if ($res->num_rows > 0) {
			return $res->result();
		}
	}

	public function search($query,$search_by) {
		$by = '';
		foreach ($search_by as $name) {
			$by .= $name.',';
		}
		$by = rtrim($by,',');
		$sql = "select title,artist,album,year,subtitle,time,path from songs where match( {$by} ) against( ? );";
		$res = $this->db->query($sql,array($query));
		if ($res->num_rows > 0) {
			return $res->result();
		}
		else {
			return false;
		}
	}

	public function total_tracks() {
		$sql = 'SELECT COUNT(title) FROM songs';
		$res = $this->db->query($sql);
		return $res->row();
	}

}
