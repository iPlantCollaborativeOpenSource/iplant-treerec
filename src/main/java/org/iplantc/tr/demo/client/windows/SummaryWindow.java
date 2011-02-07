package org.iplantc.tr.demo.client.windows;

import org.iplantc.tr.demo.client.panels.TRDetailsPanel;

import com.extjs.gxt.ui.client.widget.Window;
import com.extjs.gxt.ui.client.widget.layout.FitLayout;

public class SummaryWindow extends Window
{

	public SummaryWindow(TRDetailsPanel pnl, String idGeneFamily) {
		init(pnl, idGeneFamily);
	}
	
	private void init(TRDetailsPanel pnl, String idGeneFamily) {
		setLayout(new FitLayout());
		setHeading("Summary For Gene Family " + idGeneFamily);
		setSize(600, 400);
		add(pnl);
	}
}
