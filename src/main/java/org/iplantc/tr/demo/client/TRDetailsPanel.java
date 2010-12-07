package org.iplantc.tr.demo.client;


import com.extjs.gxt.ui.client.Style.HorizontalAlignment;
import com.extjs.gxt.ui.client.widget.Label;
import com.extjs.gxt.ui.client.widget.VerticalPanel;
import com.extjs.gxt.ui.client.widget.form.TextArea;
import com.extjs.gxt.ui.client.widget.layout.TableData;
import com.google.gwt.json.client.JSONArray;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.user.client.Element;

public class TRDetailsPanel extends VerticalPanel
{	
	private VerticalPanel pnlCounts;
	private VerticalPanel pnlGoAnnotations;
	
	/**
	 * Build from a gene family and a JSON object describing the details.
	 * 
	 * @param jsonObj JSON object describing details.
	 */
	public TRDetailsPanel(final JSONObject jsonObj)
	{
		init();
		
		initCounts(jsonObj);
	}

	private void init()
	{
		setSpacing(5);
		setHeight("100%");
		setBorders(false);
		this.setStyleAttribute("background-color", "#EDEDED");		
	}

	private int getCount(final JSONObject jsonObj, final String key)
	{
		int ret = -1; // assume failure

		if(jsonObj != null && key != null)
		{
			if(jsonObj.containsKey(key))
			{
				Double temp = jsonObj.get(key).isNumber().doubleValue();
				ret = temp.intValue();
			}
		}

		return ret;
	}

	private void addLabel(final String out, final VerticalPanel dest)
	{
		if(out != null)
		{
			Label lbl = new Label(out);

			dest.add(lbl);

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
		if(jsonObj != null)
		{
			addDuplicationEventCountLabel(jsonObj, dest);
			addSpeciationEventCountLabel(jsonObj, dest);
			addGeneCountLabel(jsonObj, dest);
			addSpeciesCountLabel(jsonObj, dest);
		}
	}

	private VerticalPanel allocateCountsPanel()
	{
		VerticalPanel ret = new VerticalPanel();

		ret.setBorders(true);
		ret.setSpacing(5);
		ret.setWidth(320);

		return ret;
	}

	private String parseGoAnnotations(JSONArray jsonAnnotations)
	{
		StringBuffer ret = new StringBuffer();
		
		if(jsonAnnotations != null)
		{		
			for(int i = 0;  i < jsonAnnotations.size(); i++)
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
		
		if(jsonObj != null)
		{
			ret.setBorders(true);
			ret.setWidth(412);
			ret.setStyleAttribute("padding", "5px");
			ret.add(new Label("GO Annotations:"));
			
			if(jsonObj != null)
			{
				JSONArray jsonText = (JSONArray)jsonObj.get("goAnnotations");		
									
				GoAnnotationsTextArea area = new GoAnnotationsTextArea(parseGoAnnotations(jsonText));
					
				ret.add(area);					
			}		
		}
		
		return ret;		
	}
	
	private void initCounts(final JSONObject jsonObj)
	{
		pnlCounts = allocateCountsPanel();

		buildCountDisplays(jsonObj, pnlCounts);
			
		pnlGoAnnotations = buildGoAnnotationsDisplay(jsonObj);
		
	}
	
	/**
	 * {@inheritDoc}
	 */
	@Override
	protected void onRender(Element parent, int index)
	{
		super.onRender(parent, index);		
	
		TableData td = new TableData();		
		td.setWidth(Integer.toString(getWidth()));
		td.setHorizontalAlign(HorizontalAlignment.LEFT);
		
		add(pnlCounts, td);		
		add(pnlGoAnnotations, td);
	}
	
	class GoAnnotationsTextArea extends TextArea
	{		
		public GoAnnotationsTextArea(String annotations)
		{			
			setSize(400,240);			
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
