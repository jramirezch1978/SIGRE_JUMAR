function KMTrackClick()
{
	window.onerror = function() {
		return true;
	}
	
	theURL=''+top.document.URL;
	theReferrer=''+top.document.referrer;

	engTest=false;
	engIndex=theURL.indexOf('engine=');
	if(engIndex>0) {
		engTest=true;
	}

	refBlocked=false;
	if(engTest || (theReferrer.length>4 && theReferrer.substring(0,4).toLowerCase()=='http')) {
		if(!engTest && typeof(BlockedReferrers)!='undefined') {
			for(idx in BlockedReferrers) {
				if(theReferrer.toLowerCase().indexOf(BlockedReferrers[idx].toLowerCase())>0) {
					refBlocked=true;
					break;
				}
			}
		}

		if(!refBlocked) {
			urlTest=theURL;
			refTest=theReferrer;
			if(refTest.indexOf('/',10)!=-1) {
				refTest=refTest.substring(0,refTest.indexOf('/',10));
			}
			if(urlTest.indexOf('/',10)!=-1) {
				urlTest=urlTest.substring(0,urlTest.indexOf('/',10));
			}
			if(refTest!=urlTest) {
				ref=escape(theReferrer);
				url=escape(theURL);
				ran=Math.round(Math.random()*100000000);
				log='http://tracking.rangeonlinemedia.com/tracking/log.php?id=758043534&loc=%2Fb2c%2Fadet.to&enginevar=engine&keywordvar=keyword&blockengines=&ref='+ref+'&url='+url+'&ran='+ran;
				logimage=new Image();
				logimage.src=log;
			}
		}
	}
}
KMTrackClick();