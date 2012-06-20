<?php

class Search extends CI_Controller {

	public function __construct() {
		parent::__construct();
		$this->load->model('Songs_Model', '', TRUE);
	}

	protected function _search($query,$search_by=array('title','artist','album')) {
		$ng = $this->ngram_converter->to_query($query,2);

		if(preg_match("/[!-~]+$/", $query)) {
			$result = $this->Songs_Model->search($query,$search_by);

			// switch to ngram-search if not found by fulltext search
			if ($result === false) {
				return array($this->Songs_Model->ngram_search($ng,$search_by),'N-gram Search (fallback)');
			}
			else {
				return array($result,'Fulltext Search');
			}
		}
		else {
			return array($this->Songs_Model->ngram_search($ng,$search_by),'N-gram Search');
		}

	}

	public function index()
	{
		$this->load->library('ngram_converter');
		parse_str($_SERVER['QUERY_STRING'],$qs);

		if (isset($qs['q'])) {
			list($result,$algorithm) = $this->_search($qs['q']);
		}
		else if (isset($qs['artist']) && $qs['artist']) {
			list($result,$algorithm) = $this->_search($qs['artist'],array('artist'));
		}
		else if (isset($qs['album']) && $qs['album']) {
			list($result,$algorithm) = $this->_search($qs['album'],array('album'));
		}
		if (isset($qs['ajax']) && $qs['ajax'] == 1)
			$ajax = true;
		else
			$ajax = false;

		$vars = array('src_base'=>'http://www.keiyac.org/musiclibrary/');
		$this->load->view('result',array(
			'result'=>$result,
			'vars'=>$vars,
			'ajax'=>$ajax,
			'search_algorithm'=>$algorithm
		));
	}
}

/* End of file welcome.php */
/* Location: ./application/controllers/welcome.php */
