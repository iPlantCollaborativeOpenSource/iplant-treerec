package org.iplantc.tr.demo.client.panels;

import org.iplantc.tr.demo.client.windows.TRUrlInfo;

import com.extjs.gxt.ui.client.Style.Scroll;
import com.extjs.gxt.ui.client.widget.Html;
import com.extjs.gxt.ui.client.widget.Label;
import com.extjs.gxt.ui.client.widget.VerticalPanel;
import com.extjs.gxt.ui.client.widget.form.TextArea;
import com.google.gwt.json.client.JSONArray;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.user.client.ui.HorizontalPanel;

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

	private int getCount(final JSONObject jsonObj, final String key)
	{
		int ret = -1; // assume failure

		if(jsonObj != null && key != null)
		{
			if(jsonObj.containsKey(key))
			{
//				Double temp = jsonObj.get(key).isNumber().doubleValue();
				Double temp = Double.valueOf(jsonObj.get(key).isString().stringValue());
				ret = temp.intValue();
			}
		}

		return ret;
	}

	private void addLabel(final String out, final VerticalPanel dest)
	{
		if(out != null)
		{
			dest.add(new Label(out));

			dest.layout();
		}
	}

	private void addDuplicationEventCountLabel(final JSONObject jsonObj, final VerticalPanel dest)
	{
		int count = getCount(jsonObj, "duplicationEvents");

		if(count > -1)
		{
			addLabel("Number of Duplication Events: " + count, dest);
		}
	}

	private void addSpeciationEventCountLabel(final JSONObject jsonObj, final VerticalPanel dest)
	{
		int count = getCount(jsonObj, "speciationEvents");

		if(count > -1)
		{
			addLabel("Number of Speciation Events: " + count, dest);
		}
	}

	private void addGeneCountLabel(final JSONObject jsonObj, final VerticalPanel dest)
	{
		int count = getCount(jsonObj, "geneCount");

		if(count > -1)
		{
			addLabel("Number of Genes: " + count, dest);
		}
	}

	private void addSpeciesCountLabel(final JSONObject jsonObj, final VerticalPanel dest)
	{
		int count = getCount(jsonObj, "speciesCount");

		if(count > -1)
		{
			addLabel("Number of Species: " + count, dest);
		}
	}

	private void buildCountDisplays(final JSONObject jsonObj, final VerticalPanel dest)
	{
		addDuplicationEventCountLabel(jsonObj, dest);
		addSpeciationEventCountLabel(jsonObj, dest);
		addGeneCountLabel(jsonObj, dest);
		addSpeciesCountLabel(jsonObj, dest);
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

		return new Html("<a href=\"" + downloadInfo.getUrl() + "\"> Multiple Sequence Alignment for Gene Tree (Amino Acid)</a>");
	}

	private Html buildAminoAcidSequenceSelection(final JSONObject jsonObj)
	{
		final TRUrlInfo downloadInfo = TRUrlInfo.extractUrlInfo(jsonObj, "downloadAminoAcidSequence");

		return new Html("<a href=\"" + downloadInfo.getUrl() + "\"> Amino Acid Sequences for Gene Family</a>");
	}

	private Html buildMultipleSequenceSelection(final JSONObject jsonObj)
	{
		final TRUrlInfo downloadInfo = TRUrlInfo.extractUrlInfo(jsonObj,
				"downloadDnaMultipleSequenceAlignment");

		return new Html("<a href=\"" + downloadInfo.getUrl() + "\"> Multiple Sequence Alignment for Gene Tree (DNA)</a>");
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

	private VerticalPanel allocateCountsPanel()
	{
		VerticalPanel ret = new VerticalPanel();

		ret.setBorders(true);
		ret.setSpacing(5);

		return ret;
	}

	private VerticalPanel allocateSelectionsPanel()
	{
		VerticalPanel ret = new VerticalPanel();

		ret.setSpacing(5);

		return ret;
	}

	private String parseGoAnnotations(JSONArray jsonAnnotations)
	{
		StringBuffer ret = new StringBuffer();

		if(jsonAnnotations != null)
		{
			for(int i = 0;i < jsonAnnotations.size();i++)
			{
				ret.append(jsonAnnotations.get(i).isString().stringValue());

				if(i < jsonAnnotations.size() - 1)
				{
					ret.append("\n");
				}
			}
		}

		return ret.toString();
	}

	private VerticalPanel buildGoAnnotationsDisplay(final JSONObject jsonObj)
	{
		VerticalPanel ret = new VerticalPanel();

		ret.setBorders(true);
		ret.setStyleAttribute("padding", "5px");
		ret.add(new Label("GO Annotations:"));

		if(jsonObj != null)
		{
			JSONArray jsonText = (JSONArray)jsonObj.get("goAnnotations");

			GoAnnotationsTextArea area = new GoAnnotationsTextArea(parseGoAnnotations(jsonText));

			ret.add(area);
		}

		return ret;
	}

	private void compose(final JSONObject jsonObj)
	{
		if(jsonObj != null)
		{
			VerticalPanel panelCounts = allocateCountsPanel();
			VerticalPanel panelSelections = allocateSelectionsPanel();

			buildCountDisplays(jsonObj, panelCounts);
			buildSelections(jsonObj, panelSelections);

			HorizontalPanel pnlTop = new HorizontalPanel();
			pnlTop.setSpacing(5);

			pnlTop.add(panelCounts);
			pnlTop.add(buildGoAnnotationsDisplay(jsonObj));

			add(pnlTop);
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
