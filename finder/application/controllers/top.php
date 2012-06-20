<?php

class Top extends CI_Controller {

	public function index()
	{
		$this->load->model('Songs_Model', '', TRUE);
		$result = $this->Songs_Model->total_tracks()->{'COUNT(title)'};
		$this->load->view('top',array('tracks'=>$result));
	}

}
