package org.iplantc.tr.demo.client.windows;

import com.extjs.gxt.ui.client.widget.Html;
import com.extjs.gxt.ui.client.widget.Window;

public class WordCloudWindow extends Window
{
	private Html panel;

	public WordCloudWindow()
	{
		init();
		compose();
	}

	private void init()
	{
		setHeading("GO terms");
		String html =
				"<style type=\"text/css\"> \n"
						+ "#htmltagcloud { \n"
						+ " text-align: center; \n"
						+ " line-height: 1; \n"
						+ "} \n"
						+ "span.tagcloud0 { font-size: 12px; } \n"
						+ "span.tagcloud0 a {text-decoration: none; } \n"
						+ "span.tagcloud1 { font-size: 13px; } \n"
						+ "span.tagcloud1 a {text-decoration: none;} \n"
						+ "span.tagcloud2 { font-size: 14px;} \n"
						+ "span.tagcloud2 a {text-decoration: none;} \n"
						+ "span.tagcloud3 { font-size: 15px;} \n"
						+ "span.tagcloud3 a {text-decoration: none;} \n"
						+ "span.tagcloud4 { font-size: 16px;} \n"
						+ "span.tagcloud4 a {text-decoration: none;} \n"
						+ "span.tagcloud5 { font-size: 17px;} \n"
						+ "span.tagcloud5 a {text-decoration: none;} \n"
						+ "span.tagcloud6 { font-size: 18px;} \n"
						+ "span.tagcloud6 a {text-decoration: none;} \n"
						+ "span.tagcloud7 { font-size: 19px;} \n"
						+ "span.tagcloud7 a {text-decoration: none;} \n"
						+ "span.tagcloud8 { font-size: 20px;} \n"
						+ "span.tagcloud8 a {text-decoration: none;} \n"
						+ "span.tagcloud9 { font-size: 21px;} \n"
						+ "span.tagcloud9 a {text-decoration: none;} \n"
						+ "span.tagcloud10 { font-size: 22px;} \n"
						+ "span.tagcloud10 a {text-decoration: none;} \n"
						+ "span.tagcloud11 { font-size: 23px;} \n"
						+ "span.tagcloud11 a {text-decoration: none;} \n"
						+ "span.tagcloud12 { font-size: 24px;} \n"
						+ "span.tagcloud12 a {text-decoration: none;} \n"
						+ "span.tagcloud13 { font-size: 25px;} \n"
						+ "span.tagcloud13 a {text-decoration: none;} \n"
						+ "span.tagcloud14 { font-size: 26px;} \n"
						+ "span.tagcloud14 a {text-decoration: none;} \n"
						+ "span.tagcloud15 { font-size: 27px;} \n"
						+ "span.tagcloud15 a {text-decoration: none;} \n"
						+ "span.tagcloud16 { font-size: 28px;} \n"
						+ "span.tagcloud16 a {text-decoration: none;} \n"
						+ "span.tagcloud17 { font-size: 29px;} \n"
						+ "span.tagcloud17 a {text-decoration: none;} \n"
						+ "span.tagcloud18 { font-size: 30px;} \n"
						+ "span.tagcloud18 a {text-decoration: none;} \n"
						+ "span.tagcloud19 { font-size: 31px;} \n"
						+ "span.tagcloud19 a {text-decoration: none;} \n"
						+ "span.tagcloud20 { font-size: 32px;} \n"
						+ "span.tagcloud20 a {text-decoration: none;} \n"
						+ "</style><div id=\"htmltagcloud\"> \n"
						+ "<div id=\"htmltagcloud\"> \n"
						+ "<span class=\"tagcloud15\"><a href=\"http://www.google.com\">circadian rhythm(23) : </a></span> \n"
						+ "<span class=\"tagcloud15\"><a href=\"http://www.google.com\">cytokinin mediated signaling pathway(23) : </a></span> \n"
						+ "<span class=\"tagcloud15\"><a href=\"http://www.google.com\">embryo development ending in seed dormancy(23) : </a></span> \n"
						+ "<span class=\"tagcloud15\"><a href=\"http://www.google.com\">red light signaling pathway(23) : </a></span> \n"
						+ "<span class=\"tagcloud15\"><a href=\"http://www.google.com\">red or far-red light signaling pathway(23) : </a></span> \n"
						+ "<span class=\"tagcloud15\"><a href=\"http://www.google.com\">regulation of circadian rhythm(23) : </a></span> \n"
						+ "<span class=\"tagcloud15\"><a href=\"http://www.google.com\">regulation of transcription(23) : </a></span> \n"
						+ "<span class=\"tagcloud15\"><a href=\"http://www.google.com\">regulation of transcription, DNA-dependent(23) : </a></span> \n"
						+ "<span class=\"tagcloud15\"><a href=\"http://www.google.com\">response to chitin(23) : </a></span> \n"
						+ "<span class=\"tagcloud15\"><a href=\"http://www.google.com\">response to cytokinin stimulus(23) : </a></span> \n"
						+ "<span class=\"tagcloud15\"><a href=\"http://www.google.com\">response to red light(23) : </a></span> \n"
						+ "<span class=\"tagcloud0\"><a href=\"http://www.google.com\">response to stress(19) : </a></span> \n"
						+ "<span class=\"tagcloud15\"><a href=\"http://www.google.com\">stem cell maintenance(23) : </a></span> \n"
						+ "<span class=\"tagcloud15\"><a href=\"http://www.google.com\">transcription(23) : </a></span> \n"
						+ "<span class=\"tagcloud15\"><a href=\"http://www.google.com\">two-component signal transduction system (phosphorelay)(23) : </a></span> \n"
						+ "</div> ";

		panel = new Html(html);
		setSize(500, 460);
	}

	private void compose()
	{
		add(panel);
	}
}
