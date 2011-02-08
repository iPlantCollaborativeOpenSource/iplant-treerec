package org.iplantc.tr.demo.client.panels;

import org.iplantc.tr.demo.client.windows.TRUrlInfo;

import com.extjs.gxt.ui.client.Style.Scroll;
import com.extjs.gxt.ui.client.widget.Html;
import com.extjs.gxt.ui.client.widget.VerticalPanel;
import com.extjs.gxt.ui.client.widget.form.TextArea;
import com.google.gwt.json.client.JSONObject;

/**
 * Tree Reconciliation details panel.
 * 
 * @author amuir
 * 
 */
public class TRDetailsPanel extends VerticalPanel
{

	/**
	 * Build from a gene family and a JSON object describing the details.
	 * 
	 * @param idGeneFamily id of gene family.
	 * @param jsonObj JSON object describing details.
	 */
	public TRDetailsPanel(final String idGeneFamily, final JSONObject jsonObj)
	{
		init();

		compose(jsonObj);
	}

	private void init()
	{
		setSpacing(5);
		setHeight("100%");
		setBorders(false);
		setStyleName("accordianbody");
		setScrollMode(Scroll.AUTO);
	}

	private void buildSelections(final JSONObject jsonObj, final VerticalPanel dest)
	{
		dest.add(buildDNASelection(jsonObj));
		dest.add(buildAminoAcidSequenceSelection(jsonObj));
		dest.add(buildMultipleSequenceSelection(jsonObj));
		dest.add(buildAminoAcidMSASelection(jsonObj));
		dest.add(buildNHXGeneTreeSelection(jsonObj));
		dest.add(buildNHXSpeciesTreeSelection(jsonObj));
		dest.add(buildNHXReconciledTreeSelection(jsonObj));
	}

	private Html buildDNASelection(final JSONObject jsonObj)
	{
		final TRUrlInfo downloadInfo = TRUrlInfo.extractUrlInfo(jsonObj, "downloadDnaSequence");

		return new Html("<a href=\"" + downloadInfo.getUrl() + "\"> DNA Sequences for Gene Family</a>");
	}

	private Html buildAminoAcidMSASelection(final JSONObject jsonObj)
	{
		final TRUrlInfo downloadInfo = TRUrlInfo.extractUrlInfo(jsonObj,
				"downloadAminoAcidMultipleSequenceAlignment");

		return new Html("<a href=\"" + downloadInfo.getUrl()
				+ "\"> Multiple Sequence Alignment for Gene Tree (Amino Acid)</a>");
	}

	private Html buildAminoAcidSequenceSelection(final JSONObject jsonObj)
	{
		final TRUrlInfo downloadInfo = TRUrlInfo.extractUrlInfo(jsonObj, "downloadAminoAcidSequence");

		return new Html("<a href=\"" + downloadInfo.getUrl()
				+ "\"> Amino Acid Sequences for Gene Family</a>");
	}

	private Html buildMultipleSequenceSelection(final JSONObject jsonObj)
	{
		final TRUrlInfo downloadInfo = TRUrlInfo.extractUrlInfo(jsonObj,
				"downloadDnaMultipleSequenceAlignment");

		return new Html("<a href=\"" + downloadInfo.getUrl()
				+ "\"> Multiple Sequence Alignment for Gene Tree (DNA)</a>");
	}

	private Html buildNHXGeneTreeSelection(final JSONObject jsonObj)
	{
		final TRUrlInfo downloadInfo = TRUrlInfo.extractUrlInfo(jsonObj, "downloadGeneTree");

		return new Html("<a href=\"" + downloadInfo.getUrl() + "\"> NHX File for Gene Tree</a>");
	}

	private Html buildNHXSpeciesTreeSelection(final JSONObject jsonObj)
	{
		final TRUrlInfo downloadInfo = TRUrlInfo.extractUrlInfo(jsonObj, "downloadSpeciesTree");

		return new Html("<a href=\"" + downloadInfo.getUrl() + "\"> Newick File for Species Tree</a>");
	}

	private Html buildNHXReconciledTreeSelection(final JSONObject jsonObj)
	{
		final TRUrlInfo downloadInfo = TRUrlInfo.extractUrlInfo(jsonObj, "downloadFatTree");

		return new Html("<a href=\"" + downloadInfo.getUrl() + "\"> NHX File for Reconciled Tree</a>");
	}

	private VerticalPanel allocateSelectionsPanel()
	{
		VerticalPanel ret = new VerticalPanel();

		ret.setSpacing(5);

		return ret;
	}

	private void compose(final JSONObject jsonObj)
	{
		if(jsonObj != null)
		{
			VerticalPanel panelSelections = allocateSelectionsPanel();

			buildSelections(jsonObj, panelSelections);
			add(panelSelections);
		}
	}

	class GoAnnotationsTextArea extends TextArea
	{
		public GoAnnotationsTextArea(String annotations)
		{
			setSize(400, 140);
			setValue(annotations);
			setReadOnly(true);
		}

		/**
		 * {@inheritDoc}
		 */
		@Override
		protected void afterRender()
		{
			super.afterRender();
			el().setElementAttribute("spellcheck", "false");
		}
	}
}
